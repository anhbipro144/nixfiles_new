import { readFile, mkdtemp, symlink, rm } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { tmpdir } from 'node:os';
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';
import { parseArgs } from 'node:util';

export function semesterFromAgents(text) {
  const ids = [...new Set([...text.matchAll(/^\s*(?:[-*]\s*)?(?:\*\*)?semester\s+id(?:\*\*)?\s*[:=]\s*(?:\*\*)?(\d+)\b/gim)].map(m => m[1]))];
  if (ids.length !== 1) throw new Error('AGENTS.md must specify one unambiguous Semester ID.');
  return ids[0];
}

export function weekSections(sections, week) {
  const matches = name => [...String(name).normalize('NFC').matchAll(/(?:tuần|tuan|week)\s*0*(\d+)\b/giu)].some(m => Number(m[1]) === week);
  const selected = new Set(sections.filter(s => matches(s.name)).map(s => s.id));
  let size;
  do {
    size = selected.size;
    for (const section of sections) if (selected.has(section.parent)) selected.add(section.id);
  } while (selected.size !== size);
  return sections.filter(s => selected.has(s.id));
}

export function activityState(value) {
  if (value === 0) return 'not done';
  if (value === 1) return 'done';
  if (value === 2) return 'done — passed';
  if (value === 3) return 'done — failed';
  return 'status unavailable';
}

function safeModuleUrl(value, site) {
  if (!value) return undefined;
  try {
    const url = new URL(value, site + '/');
    if (url.origin !== new URL(site).origin || url.username || url.password) return undefined;
    for (const key of [...url.searchParams.keys()]) if (key !== 'id') url.searchParams.delete(key);
    return url.href;
  } catch { return undefined; }
}

export function summarizeCourse(course, sections, week, site) {
  const selected = weekSections(sections, week);
  const seen = new Set();
  const activities = [];
  for (const section of selected) {
    for (const activity of section.activities ?? []) {
      if (['label', 'subsection'].includes(activity.modname) || seen.has(activity.id)) continue;
      seen.add(activity.id);
      activities.push({
        id: activity.id, name: activity.name, type: activity.modname,
        section: section.name, section_id: section.id,
        state: activityState(activity.completion),
        locked: activity.visible === false || activity.uservisible === false,
        url: safeModuleUrl(activity.url, site),
      });
    }
  }
  return {
    id: course.id, name: course.fullname || course.shortname,
    week_found: selected.length > 0,
    sections: selected.map(s => ({id: s.id, name: s.name})), activities,
  };
}

export async function collect(client, semester, week, site) {
  const enrolled = await client.getCourses();
  const prefix = new RegExp('^' + semester + '(?:[-_\\s]|$)');
  const courses = [];
  for (const course of enrolled.filter(c => prefix.test(c.shortname ?? '') || prefix.test(c.fullname ?? ''))) {
    try {
      courses.push(summarizeCourse(course, await client.getCourseContents(course.id), week, site));
    } catch {
      courses.push({id:course.id, name:course.fullname || course.shortname, error:'Course inspection failed; status unavailable.'});
    }
  }
  const activities = courses.flatMap(c => c.activities ?? []);
  return {
    semester, week, checked_at: new Date().toISOString(), site,
    courses,
    totals: {
      courses: courses.length,
      failed_courses: courses.filter(c => c.error).length,
      missing_week_courses: courses.filter(c => !c.error && !c.week_found).length,
      activities: activities.length,
      done: activities.filter(a => a.state.startsWith('done')).length,
      not_done: activities.filter(a => a.state === 'not done').length,
      status_unavailable: activities.filter(a => a.state === 'status unavailable').length,
    },
  };
}

async function main() {
  const { values } = parseArgs({ options: {
    week: {type:'string'}, directory: {type:'string',default:process.cwd()},
    repository: {type:'string'}, site: {type:'string'}, help: {type:'boolean'},
  }});
  if (values.help) {
    console.log('Usage: node collect-week.mjs --week N --repository /path/to/moodle-cli --site https://moodle.example [--directory /semester/folder]');
    return;
  }
  const week = Number(values.week);
  if (!Number.isSafeInteger(week) || week < 1 || !values.repository || !values.site) {
    throw new Error('Supply a positive integer --week, --repository, and --site.');
  }
  const semester = semesterFromAgents(await readFile(join(resolve(values.directory), 'AGENTS.md'), 'utf8'));
  const siteUrl = new URL(values.site);
  if (!['http:', 'https:'].includes(siteUrl.protocol) || siteUrl.username || siteUrl.password || siteUrl.search || siteUrl.hash) {
    throw new Error('Use the Moodle site base URL without credentials, query, or fragment.');
  }
  const site = siteUrl.href.replace(/\/+$/, '');
  const repository = resolve(values.repository);
  const require = createRequire(join(repository, 'package.json'));
  const { build } = require('esbuild');
  const temporary = await mkdtemp(join(tmpdir(), 'moodle-week-report-'));
  try {
    await symlink(join(repository, 'node_modules'), join(temporary, 'node_modules'), 'dir');
    const outfile = join(temporary, 'client.mjs');
    await build({
      stdin: {contents:'export { createMoodleClient } from "./src/client.ts";',resolveDir:repository,sourcefile:'report-client.ts'},
      bundle:true,platform:'node',format:'esm',packages:'external',outfile,logLevel:'silent',
    });
    const { createMoodleClient } = await import(pathToFileURL(outfile).href);
    console.log(JSON.stringify(await collect(await createMoodleClient(site), semester, week, site)));
  } finally {
    await rm(temporary, {recursive:true,force:true});
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  main().catch(() => {
    console.error('Report collection failed. Check arguments, AGENTS.md, the CLI checkout, and authenticated host/keyring access. No credentials printed.');
    process.exitCode = 1;
  });
}
