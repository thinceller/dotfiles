require('nvim-test').setup {
  term = 'toggleterm',
  termOpts = {
    direction = 'horizontal'
  }
}

require('nvim-test.runners.rspec'):setup {
  command = 'bundle exec rspec'
}
