/**
 * Bun --compile packaging script.
 *
 * Note: Bun.build({ compile: true }) ignores `outfile` and always writes
 *       <entrypoint-stem>.exe to the CWD. We move it afterwards.
 *
 * Run from project root:
 *   bun run packaging/build-compile.ts
 */

import { getMacroDefines } from '../scripts/defines.ts'
import { mkdir, rename, rm, copyFile } from 'fs/promises'
import { existsSync } from 'fs'
import { join, basename } from 'path'

const projectRoot = new URL('..', import.meta.url).pathname.replace(/^\//, '').replace(/\/$/, '')
const outDir = join(import.meta.dir, 'output')
await mkdir(outDir, { recursive: true })

// Bun writes <entrypoint-stem>.exe in the CWD (project root)
const bunOutputName = 'cli.exe'            // from src/entrypoints/cli.tsx → cli.exe
const bunOutputPath = join(projectRoot, bunOutputName)
const finalPath     = join(outDir, 'claude-core.exe')

const DEFAULT_BUILD_FEATURES = [
  'AGENT_TRIGGERS_REMOTE', 'CHICAGO_MCP', 'VOICE_MODE', 'SHOT_STATS',
  'PROMPT_CACHE_BREAK_DETECTION', 'TOKEN_BUDGET', 'AGENT_TRIGGERS',
  'ULTRATHINK', 'BUILTIN_EXPLORE_PLAN_AGENTS', 'LODESTONE',
  'EXTRACT_MEMORIES', 'VERIFICATION_AGENT', 'KAIROS_BRIEF', 'AWAY_SUMMARY',
  'ULTRAPLAN', 'DAEMON', 'ACP', 'WORKFLOW_SCRIPTS', 'HISTORY_SNIP',
  'CONTEXT_COLLAPSE', 'MONITOR_TOOL', 'FORK_SUBAGENT', 'KAIROS',
  'COORDINATOR_MODE', 'LAN_PIPES', 'BG_SESSIONS', 'TEMPLATES', 'POOR',
  'BUDDY', 'TRANSCRIPT_CLASSIFIER', 'BRIDGE_MODE',
]

const envFeatures = Object.keys(process.env)
  .filter(k => k.startsWith('FEATURE_'))
  .map(k => k.replace('FEATURE_', ''))
const features = [...new Set([...DEFAULT_BUILD_FEATURES, ...envFeatures])]

console.log(`Building standalone EXE → ${finalPath}`)
console.log(`Features (${features.length}): ${features.join(', ')}`)
console.log('')

// Clean up any leftover from previous run
if (existsSync(bunOutputPath)) await rm(bunOutputPath)
if (existsSync(finalPath))     await rm(finalPath)

const result = await Bun.build({
  entrypoints: ['src/entrypoints/cli.tsx'],
  // outfile is ignored by Bun in compile mode — bun uses the entrypoint stem
  target: 'bun',
  compile: true,
  define: getMacroDefines(),
  features,
})

if (!result.success) {
  console.error('Build failed:')
  for (const log of result.logs) console.error(log)
  process.exit(1)
}

// Locate the produced file from result.outputs
const produced = (result.outputs[0] as any)?.path as string | undefined
const actualPath = produced ?? bunOutputPath

if (!existsSync(actualPath)) {
  console.error(`Build reported success but output not found at: ${actualPath}`)
  process.exit(1)
}

// Move to final destination
await rename(actualPath, finalPath)

const size = (await Bun.file(finalPath).arrayBuffer()).byteLength
console.log(`\nSuccess! ${finalPath}`)
console.log(`Size: ${(size / 1024 / 1024).toFixed(1)} MB`)

// Copy bridge.py alongside claude-core.exe (Computer Use Windows feature)
const bridgeSrc = join(projectRoot, 'src/utils/computerUse/win32/bridge.py')
const bridgeDst = join(outDir, 'bridge.py')
if (existsSync(bridgeSrc)) {
  await copyFile(bridgeSrc, bridgeDst)
  console.log(`Copied bridge.py → ${bridgeDst}`)
}
