import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as fs from 'node:fs/promises';
import { promisify } from 'node:util';
import { execFile } from 'node:child_process';
import { createHash } from 'node:crypto';
import path from 'node:path';
import os from 'node:os';
const exec=promisify(execFile);
async function fixture() {
  const root=await fs.mkdtemp(path.join(os.tmpdir(),'day-one-image-fixture-'));
  const bin=path.join(root,'docker');
  await fs.writeFile(bin,`#!${process.execPath}\nconst fs=require('node:fs');\nfs.writeFileSync(process.argv[process.argv.indexOf('--output')+1],'fixture image');\nif(process.env.DAY_ONE_TEST_IMAGE_FAIL)process.exit(9);\n`,{mode:0o755});
  const script=path.resolve('scripts/image-artifact.mjs');
  const run=(out:string,fail=false)=>exec(process.execPath,[script,'export',out],{env:{...process.env,PATH:root,DAY_ONE_TEST_IMAGE_FAIL:fail?'1':''}});
  return {root,run};
}
test('image export reserves a destination, hashes its contents and refuses overwrites',async()=>{
  const f=await fixture();try{
    const dir=path.join(f.root,'output');await f.run(dir);
    const file=path.join(dir,'day-one-mac-mcp-0.1.0-docker.tar');
    const contents=await fs.readFile(file);const sum=await fs.readFile(file+'.sha256','utf8');
    assert.equal(sum,createHash('sha256').update(contents).digest('hex')+'  '+path.basename(file)+'\n');
    await assert.rejects(f.run(dir),/EEXIST/);assert.deepEqual(await fs.readFile(file),contents);
  }finally{await fs.rm(f.root,{recursive:true});}
});
test('failed image export removes the temporary file and creates no misleading checksum',async()=>{
  const f=await fixture();try{
    const dir=path.join(f.root,'failed');await assert.rejects(f.run(dir,true),/Docker exited 9/);
    assert.deepEqual(await fs.readdir(dir),[]);
  }finally{await fs.rm(f.root,{recursive:true});}
});
