
// Block
module("Block tests", {
  setup: function() {
    block = new Block([], []);
  },
  teardown: function() {
    block = null;
  }
});

test("id returns a uniq identifier for the block", function() {
  equal( block.id, "Block", "Default block id is 'Block'" );
});

// Trials
// ...