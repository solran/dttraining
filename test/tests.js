
// Block
module("Block tests", {
  setup: function() {
    block = Fixtures.Blocks['simple'];
  },
  teardown: function() {
    block = null;
  }
});

test("id returns a uniq identifier for the block", function() {
  equal( block.id, "Block", "Default block id is 'Block'" );
});

test("attempts contains a number of attempts based on number_of_attempts", function() {
  equal( block.attempt_collection.length, 10, "Attempts are created when the block is instantiated" )
});

// Trials
// ...