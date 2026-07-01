// public class NT_ModifierCycleDetectionHandler {

//     private static final Integer MAX_DEPTH = 10;

//     /**
//      * Entry point called from trigger.
//      * For each modifier being saved, builds the full connected graph around
//      * that modifier and checks for cycles and depth violations.
//      */
//     public static void checkForCycles(List<Modifier__c> newModifiers) {
//         for (Modifier__c mod : newModifiers) {
//             if (mod.Modifier_Rate_Card__c == null) continue;
//             if (mod.Rate_Card__c == null) continue;

//             // Build the full graph of all Rate Cards connected to this modifier,
//             // expanding both upstream and downstream until no new nodes are found.
//             Map<Id, Id> forwardEdges = buildConnectedGraph(mod.Rate_Card__c, mod.Modifier_Rate_Card__c, mod.Id);

//             // Find the root: the Rate Card that nothing points to
//             Set<Id> pointedTo = new Set<Id>(forwardEdges.values());
//             Id root = null;
//             for (Id rcId : forwardEdges.keySet()) {
//                 if (!pointedTo.contains(rcId)) {
//                     root = rcId;
//                     break;
//                 }
//             }
//             // If no root found (everything is pointed to = cycle already exists),
//             // just start from the current record's Rate Card
//             if (root == null) root = mod.Rate_Card__c;

//             // Check self-reference explicitly before traversal
//             if (mod.Rate_Card__c == mod.Modifier_Rate_Card__c) {
//                 mod.addError('Modifier cannot reference itself');
//                 continue;
//             }

//             String errorMsg = traverse(root, forwardEdges);
//             if (errorMsg != null) {
//                 mod.addError(errorMsg);
//             }
//         }
//     }

//     /**
//      * Builds a complete map of RateCard Id → next RateCard Id (forward edges)
//      * for the entire connected chain, by expanding outward from the current
//      * modifier in BOTH directions until no new nodes are discovered.
//      *
//      * The in-memory edge (savingRateCardId → targetRateCardId) is overlaid
//      * so the graph reflects the state after the pending save.
//      */
//     private static Map<Id, Id> buildConnectedGraph(
//         Id savingRateCardId,
//         Id targetRateCardId,
//         Id savingModifierId
//     ) {
//         // Start with the in-memory edge from the record being saved
//         Map<Id, Id> edges = new Map<Id, Id>();
//         edges.put(savingRateCardId, targetRateCardId);

//         // Seed: we need to expand from both ends of the new edge
//         Set<Id> toExpand = new Set<Id>{ savingRateCardId, targetRateCardId };
//         Set<Id> visited  = new Set<Id>(toExpand);

//         // Iteratively expand until no new Rate Cards are discovered
//         for (Integer i = 0; i <= MAX_DEPTH * 2; i++) {
//             if (toExpand.isEmpty()) break;

//             // Query modifiers whose Rate_Card__c OR Modifier_Rate_Card__c
//             // is in our current frontier — covers both directions at once
//             List<Modifier__c> mods = [
//                 SELECT Id, Rate_Card__c, Modifier_Rate_Card__c
//                 FROM Modifier__c
//                 WHERE (Rate_Card__c IN :toExpand OR Modifier_Rate_Card__c IN :toExpand)
//                   AND Id != :savingModifierId  // exclude the record being saved (use in-memory value)
//                   AND Modifier_Rate_Card__c != null
//             ];

//             Set<Id> newNodes = new Set<Id>();
//             for (Modifier__c m : mods) {
//                 // Add the forward edge
//                 if (!edges.containsKey(m.Rate_Card__c)) {
//                     edges.put(m.Rate_Card__c, m.Modifier_Rate_Card__c);
//                 }
//                 // Collect any Rate Cards we haven't visited yet
//                 if (!visited.contains(m.Rate_Card__c)) {
//                     newNodes.add(m.Rate_Card__c);
//                     visited.add(m.Rate_Card__c);
//                 }
//                 if (!visited.contains(m.Modifier_Rate_Card__c)) {
//                     newNodes.add(m.Modifier_Rate_Card__c);
//                     visited.add(m.Modifier_Rate_Card__c);
//                 }
//             }
//             toExpand = newNodes;
//         }

//         return edges;
//     }

//     /**
//      * Traverses the chain forward from rootRateCardId using the edge map.
//      * Detects cycles and depth violations.
//      * Returns an error string, or null if the chain is clean.
//      */
//     private static String traverse(Id rootRateCardId, Map<Id, Id> edges) {
//         Set<Id> visited = new Set<Id>();
//         Id pointer = rootRateCardId;
//         Integer depth = 0;

//         while (pointer != null && edges.containsKey(pointer)) {

//             if (depth >= MAX_DEPTH) {
//                 return 'Modifier chain exceeds maximum depth of ' + MAX_DEPTH;
//             }

//             if (visited.contains(pointer)) {
//                 return 'Modifier chain would create a circular reference';
//             }

//             visited.add(pointer);
//             pointer = edges.get(pointer);
//             depth++;
//         }

//         return null;
//     }
// }


public class NT_ModifierCycleDetectionHandler {

    private static final Integer MAX_DEPTH = 10;

    /**
     * Entry point called from trigger.
     * For each modifier being saved, builds the full connected graph around
     * that modifier and checks for cycles and depth violations.
     */
    public static void checkForCycles(List<Modifier__c> newModifiers) {
        for (Modifier__c mod : newModifiers) {
            if (mod.Modifier_Rate_Card__c == null) continue;
            if (mod.Rate_Card__c == null) continue;

            // Check self-reference explicitly before traversal
            if (mod.Rate_Card__c == mod.Modifier_Rate_Card__c) {
                mod.addError('Modifier cannot reference itself');
                continue;
            }

            // Build the full graph as an adjacency list (supports multiple outgoing edges per node)
            Map<Id, Set<Id>> adjList = buildConnectedGraph(mod.Rate_Card__c, mod.Modifier_Rate_Card__c, mod.Id);

            // Find roots: Rate Cards that no other Rate Card points to
            Set<Id> pointedTo = new Set<Id>();
            for (Set<Id> targets : adjList.values()) {
                pointedTo.addAll(targets);
            }
            Set<Id> roots = new Set<Id>();
            for (Id rcId : adjList.keySet()) {
                if (!pointedTo.contains(rcId)) {
                    roots.add(rcId);
                }
            }
            // If no root found (everything is pointed to = cycle already exists),
            // just start from the current record's Rate Card
            if (roots.isEmpty()) roots.add(mod.Rate_Card__c);

            // DFS from every root to catch cycles and depth violations on all paths
            String errorMsg = null;
            for (Id root : roots) {
                errorMsg = traverseDFS(root, adjList, new Set<Id>(), 0);
                if (errorMsg != null) break;
            }

            if (errorMsg != null) {
                mod.addError(errorMsg);
            }
        }
    }

    /**
     * Builds a complete adjacency list: RateCard Id → Set of next RateCard Ids
     * for the entire connected chain, by expanding outward from the current
     * modifier in BOTH directions until no new nodes are discovered.
     *
     * The in-memory edge (savingRateCardId → targetRateCardId) is overlaid
     * so the graph reflects the state after the pending save.
     */
    private static Map<Id, Set<Id>> buildConnectedGraph(
        Id savingRateCardId,
        Id targetRateCardId,
        Id savingModifierId
    ) {
        // Start with the in-memory edge from the record being saved
        Map<Id, Set<Id>> edges = new Map<Id, Set<Id>>();
        addEdge(edges, savingRateCardId, targetRateCardId);

        // Seed: we need to expand from both ends of the new edge
        Set<Id> toExpand = new Set<Id>{ savingRateCardId, targetRateCardId };
        Set<Id> visited  = new Set<Id>(toExpand);

        // Iteratively expand until no new Rate Cards are discovered
        for (Integer i = 0; i <= MAX_DEPTH * 2; i++) {
            if (toExpand.isEmpty()) break;

            List<Modifier__c> mods = [
                SELECT Id, Rate_Card__c, Modifier_Rate_Card__c
                FROM Modifier__c
                WHERE (Rate_Card__c IN :toExpand OR Modifier_Rate_Card__c IN :toExpand)
                  AND Id != :savingModifierId
                  AND Modifier_Rate_Card__c != null
            ];

            Set<Id> newNodes = new Set<Id>();
            for (Modifier__c m : mods) {
                // Add every edge (adjacency list supports multiple per source)
                addEdge(edges, m.Rate_Card__c, m.Modifier_Rate_Card__c);

                if (!visited.contains(m.Rate_Card__c)) {
                    newNodes.add(m.Rate_Card__c);
                    visited.add(m.Rate_Card__c);
                }
                if (!visited.contains(m.Modifier_Rate_Card__c)) {
                    newNodes.add(m.Modifier_Rate_Card__c);
                    visited.add(m.Modifier_Rate_Card__c);
                }
            }
            toExpand = newNodes;
        }

        return edges;
    }

    /** Helper to add an edge to the adjacency list */
    private static void addEdge(Map<Id, Set<Id>> edges, Id fromId, Id toId) {
        if (!edges.containsKey(fromId)) {
            edges.put(fromId, new Set<Id>());
        }
        edges.get(fromId).add(toId);
    }

    /**
     * Recursive DFS traversal from a given node.
     * Detects cycles (node already in current path) and depth violations.
     * Returns an error string, or null if all paths from this node are clean.
     */
    private static String traverseDFS(Id current, Map<Id, Set<Id>> edges, Set<Id> pathVisited, Integer depth) {
        if (depth > MAX_DEPTH) {
            return 'Modifier chain exceeds maximum depth of ' + MAX_DEPTH;
        }

        if (pathVisited.contains(current)) {
            return 'Modifier chain would create a circular reference';
        }

        if (!edges.containsKey(current)) {
            return null; // leaf node, no outgoing edges
        }

        pathVisited.add(current);

        for (Id neighbor : edges.get(current)) {
            String errorMsg = traverseDFS(neighbor, edges, pathVisited, depth + 1);
            if (errorMsg != null) {
                return errorMsg;
            }
        }

        pathVisited.remove(current); // backtrack for other paths
        return null;
    }
}