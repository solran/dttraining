window.Fixtures = {};

// instructions
Fixtures.Instructions = {
  'instruction1': new Instruction('Instruction1'),
  'instruction2': new Instruction('Instruction2')
};

// stimulus
Fixtures.Stimulus = {
  'stimulus1': new Stimulus('circle', 'j'),
  'stimulus2': new Stimulus('square', 'k')
};

// trials
Fixtures.Trials = {
  'empty': new Trial(),
  'single': new Trial(Fixtures.Stimulus['stimulus1']),
  'double': new Trial(Fixtures.Stimulus['stimulus1'], Fixtures.Stimulus['stimulus2'])
};

// blocks
Fixtures.Blocks = {
  'simple': new Block([Fixtures.Instructions['instruction1']], [Fixtures.Trials['single']], {number_of_attempts: 10})
};