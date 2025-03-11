local bfs_shortest_path = require("util.note_node_path").bfs_shortest_path

describe("BFS Shortest Path", function()
  it("should return the shortest path in a simple graph", function()
    local graph = {
      A = { "B", "C" },
      B = { "A", "D", "E" },
      C = { "A", "F" },
      D = { "B" },
      E = { "B", "F" },
      F = { "C", "E" },
    }
    local path = bfs_shortest_path(graph, "A", "F")
    assert.are.same({ "A", "C", "F" }, path)
  end)

  it("should return nil if no path exists", function()
    local graph = {
      A = { "B" },
      B = { "A" },
      C = { "D" },
      D = { "C" },
    }
    local path = bfs_shortest_path(graph, "A", "D")
    assert.is_nil(path)
  end)

  it("should return nil if start or goal node does not exist", function()
    local graph = {
      A = { "B" },
      B = { "A" },
    }
    local path = bfs_shortest_path(graph, "A", "C")
    assert.is_nil(path)
  end)

  it("should return the path when start and goal are the same", function()
    local graph = {
      A = { "B", "C" },
      B = { "A" },
      C = { "A" },
    }
    local path = bfs_shortest_path(graph, "A", "A")
    assert.are.same({ "A" }, path)
  end)

  it("should handle a graph with a single node", function()
    local graph = {
      A = {},
    }
    local path = bfs_shortest_path(graph, "A", "A")
    assert.are.same({ "A" }, path)
  end)

  it("should handle a graph with cycles", function()
    local graph = {
      A = { "B" },
      B = { "A", "C" },
      C = { "B", "D" },
      D = { "C", "A" },
    }
    local path = bfs_shortest_path(graph, "A", "D")
    assert.are.same({ "A", "B", "C", "D" }, path)
  end)

  it("should return one of the shortest paths if multiple exist", function()
    local graph = {
      A = { "B", "C" },
      B = { "D" },
      C = { "D" },
      D = {},
    }
    local path = bfs_shortest_path(graph, "A", "D")
    assert.is_true(
      (path[1] == "A" and path[2] == "B" and path[3] == "D") or (path[1] == "A" and path[2] == "C" and path[3] == "D")
    )
  end)

  -- New test case for a longer path
  it("should find the shortest path in a larger graph", function()
    local graph = {
      A = { "B", "C" },
      B = { "D", "E" },
      C = { "F" },
      D = { "G" },
      E = { "H" },
      F = { "I" },
      G = { "J" },
      H = { "J" },
      I = { "J" },
      J = {},
    }
    local path = bfs_shortest_path(graph, "A", "J")
    assert.are.same({ "A", "B", "D", "G", "J" }, path)
  end)
end)
