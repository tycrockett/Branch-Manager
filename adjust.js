const fs = require('fs');

const args = process.argv.slice(2);
const remove = '/Users/ty.crockett@getweave.com';
const current = process.cwd();

fs.readFile(`${remove}/repo-file-settings.json`, (err, response) => {
  let data = {};
  if (response) {
    const json = JSON.parse(response);
    data = json;
  }

  console.log(data);

  const key = args[0];
  const value = args[1];
  console.log(key, value, current, args[2]);

  const directory = `${current}/${args[2].replace('/', '')}`;

  const newData = {
    ...data,
    [directory]: {
      ...(data[directory] || {}),
      shortcut: value,
    }
  }
  const jsonify = JSON.stringify(newData);
  fs.writeFile(`${remove}/repo-file-settings.json`, jsonify, (err, data) => {
    console.log(`Completed Update!`);
  });
  
})