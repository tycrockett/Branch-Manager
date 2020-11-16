const fs = require('fs');
const myArgs = process.argv.slice(2, 3);
const files = process.argv.slice(3);

const column = (arr, width) => {
  return arr.reduce((prev, item) => {
    const string = item || '';
    const len = string.length;
    const space = width - len;
    let spaceValue = '';
    for (let i = 0; i < space; i++) spaceValue += ' ';
    return `${prev}${string}${spaceValue}`;
  }, '');

}

const remove = '/Users/ty.crockett@getweave.com';
const current = process.cwd();
if (!myArgs[0]) {
  console.clear();
  console.log(current);
  console.log('-------------------------------');
}

const handleDuplicates = (value, obj) => {
  let newValue = value;
  if (value in obj) newValue = handleDuplicates(value += value[0], obj);
  return newValue;
}

fs.readFile(`${remove}/repo-file-settings.json`, (err, response) => {

  let data = {};
  if (response) {
    const json = JSON.parse(response);
    data = json;
  }

  const shortcuts = files.reduce((previous, filenameRaw) => {
    const filename = filenameRaw.replace('/', '');
    const seperate = filename.split('-');
    let shortcutValue = seperate.reduce((prev, item) => {
      return prev + item[0].toLowerCase();
    }, '');
    
    let shortcut = handleDuplicates(shortcutValue, previous);

    const directoryKey = `${current}/${filename}`;
    if (directoryKey in data && 'shortcut' in data[directoryKey]) {
      shortcut = data[directoryKey].shortcut;
    }
  
    if (!myArgs[0]) console.log(column([shortcut, filename], 10));
  
    return { ...previous, [shortcut]: filename };
  }, {});
  
  if (myArgs[0]) console.log(shortcuts[myArgs[0]]);
  
});  
