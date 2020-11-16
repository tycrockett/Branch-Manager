const simpleGit = require('simple-git/promise');
const openBrowser = require('open');
const { format } = require('date-fns');
const { colors, column } = require('./utils');

const git = simpleGit();

const args = process.argv.slice(2);

const getCurrent = async () => {
  const data = await git.branchLocal();
  return data?.current;
}

const checkRemote = async (branch = 'origin') => {
  const data = await git.getRemotes(true);
  return data.find((item) => {
    return item.name === branch
  });
}

const handleArgs = async (arguments) => {
  try {
    switch (arguments[0]) {

      case 'n':
      case 'new':
        if (arguments[1]) {
          console.log();
          await git.checkout('master');
          process.stdout.write(colors.green);
          console.log('Updating master...');
          await git.pull('origin', 'master');
          console.log(`Switching to`, `${colors.bright}${colors.white}${arguments[1]}`);
          await git.checkoutLocalBranch(arguments[1]);
        } else {
          console.log('Need a branch name');
        }
        break;
        
      case 'u':
      case 'update':
        const current_update = await getCurrent();
        await git.checkout('master');
        await git.pull('origin', 'master');
        await git.checkout(current_update);
        break;

      case 's':
      case 'status':
        const status = await git.status();
        console.log();
        console.log('Changes:');
        // console.log(status);
        if (status?.modified.length) {
          process.stdout.write(colors.cyan);
          status?.modified.forEach((file) => console.log(`  `, file));
          process.stdout.write(colors.reset);
        }
        if (status?.not_added.length) {
          process.stdout.write(colors.cyan);
          process.stdout.write(colors.dim);
          status.not_added.forEach((file) => console.log(`  `, file));
          process.stdout.write(colors.reset);
        }

        if (status?.deleted.length) {
          console.log('Deleted:');
          process.stdout.write(colors.red);
          status?.deleted.forEach((file) => console.log(`  `, file));
          process.stdout.write(colors.reset);
        }

        if (!status?.modified.length &&
          !status?.not_added.length &&
          !status?.deleted.length
          ) console.log('There are no changes.');

        break;

      case 'd':
      case 'delete':
        const current_delete = await getCurrent();
        await git.checkout('master');
        process.stdout.write(colors.red);
        console.log('Deleting local branch...');
        await git.deleteLocalBranch(current_delete);

        const data_delete = await checkRemote(current_delete);
        if (!!data_delete) {
          console.log('Deleting remote branch...');
          await git.push(['origin', '--delete', current_delete])
          await git.removeRemote(current_delete)
          process.stdout.write(colors.green);
          console.log('Done');          
        }

        break;

      case 'c':
      case 'clear':
        await git.add('./*');
        await git.stash();
        break;

      case '.':
        if (arguments[1]) {
          await git.add('./*');
          await git.commit(arguments[1]);
          const current_period = await getCurrent();
          const data_period = await checkRemote(current_period);
          if (!!data_period) {
            await git.push();
          }
        } else {
          console.log('Add a commit description.');
        }
        break;
      
      case 'log':
        const current_log = await getCurrent();
        const logOptions = [ `-n`, `5`, `master..${current_log}` ];
        const data_log = await git.log(logOptions);
        console.log();
        data_log.all.forEach((item) => {
          console.log('----------');
          process.stdout.write(colors.green);
          process.stdout.write(colors.bright);
          console.log(item.message);
          process.stdout.write(colors.reset);
          console.log(item.author_name);
          console.log(format(new Date(item.date), 'MM/dd/yyyy h:mm:ss a'));
          process.stdout.write(colors.dim);
          console.log(item.hash);
          process.stdout.write(colors.reset);
        })
        break;

      case 'remote':
        const current_remote = await getCurrent();
        const data_remote = await checkRemote('origin');
        const ref_remote = data_remote?.refs?.push?.split(':')?.[1];
        const url = `https://github.com/${ref_remote.replace('.git', '/tree')}`;
        openBrowser(`${url}/${current_remote}`);
        break

      case 'has-remote':
        const current_has_remote = await getCurrent();
        const data_has_remote = await checkRemote(current_has_remote);
        console.log(data_has_remote);
        break;

      case 'list-remote':
        const data_list_remote = await git.getRemotes(true);
        console.log(data_list_remote);
        break;
      
      case 'pushup':
        const current_pushup = await getCurrent();
        console.log('Setting upstream...');
        await git.push(['--set-upstream', 'origin', current_pushup]);
        await git.addRemote(current_pushup);
        break;

      default:
        const data = await git.branch('');
        console.log();
        console.log('Branches:');
        data.all.forEach((branch, idx) => {
          const item = data.branches[branch];
          let value = '  ';
          if (item.current) {
            process.stdout.write(colors.green);
            value = ' >';
          }
          console.log(value, idx + 1, branch);
        })

    }






  } catch (err) {
    console.log('NOT A GIT REPOSITORY');
    console.log(err);
  }
  process.stdout.write(colors.reset);
}


handleArgs(args);