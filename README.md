# prefix-map

__[Ceylon module](https://modules.ceylon-lang.org/repo/1/herd/prefixmap/0.0.5/module-doc/api/index.html) that provides general-purpose maps with support to prefix queries__
   
The module defines the following interfaces:
   
- [`PrefixMap`](https://modules.ceylon-lang.org/repo/1/herd/prefixmap/0.0.5/module-doc/api/PrefixMap.type.html), 
  an immutable [`SortedMap`](https://modules.ceylon-lang.org/repo/1/ceylon/collection/1.2.0/module-doc/api/SortedMap.type.html)
  that supports prefix queries and is keyed by non-empty sequences of
  `Comparable` objects;
- [`TernaryTreeMap`](https://modules.ceylon-lang.org/repo/1/herd/prefixmap/0.0.5/module-doc/api/TernaryTreeMap.type.html), 
  a mutable [`PrefixMap`](https://modules.ceylon-lang.org/repo/1/herd/prefixmap/0.0.5/module-doc/api/PrefixMap.type.html) 
  backed by a ternary search tree.
     
[`TernaryTreeMap`](https://modules.ceylon-lang.org/repo/1/herd/prefixmap/0.0.5/module-doc/api/TernaryTreeMap.type.html)
is an abstract supertype for the following concrete implementations:
   
- [`TernarySearchTreeMap`](https://modules.ceylon-lang.org/repo/1/herd/prefixmap/0.0.5/module-doc/api/TernarySearchTreeMap.type.html), 
  a mutable [`PrefixMap`](https://modules.ceylon-lang.org/repo/1/herd/prefixmap/0.0.5/module-doc/api/PrefixMap.type.html)
  based on a ternary search tree;  
- [`TernarySplayTreeMap`](https://modules.ceylon-lang.org/repo/1/herd/prefixmap/0.0.5/module-doc/api/TernarySplayTreeMap.type.html), 
  a mutable [`PrefixMap`](https://modules.ceylon-lang.org/repo/1/herd/prefixmap/0.0.5/module-doc/api/PrefixMap.type.html)
  based on a ternary splay tree.
     
A _ternary search tree_, also known as a _lexicographic search tree_,
is a kind of prefix tree whose nodes contain key elements, rather
than complete keys. 
   
The figure below shows a ternary search tree whose keys are sequences 
of characters. Each node contain one element (a character) of a key.
The keys in this tree are the words "as", "at", "bat", "bats", "bog",
"boy", "caste", "cats", "day", "dogs", "donut", and "door". Squares
denote terminal nodes. A terminal node contains the last element of
a key. It also contains the item (not shown) associated with the key.

![Ternary search tree image](https://raw.githubusercontent.com/reverbel/prefix-map/master/doc/resources/ternary-search-tree.png "Ternary search tree example")
     
For a very short, formal and precise definition of ternary search tree, 
see pages 674-676 of Sleator and Tarjan's paper ["Self-Adjusting Binary 
Search Trees"][sleator-tarjan], from which the image above was taken.
The relevant part is in section 6, "Two Applications of Splaying",
starting at the bottom of page 674 and going up to the first paragraph
of page 676. (Sleator and Tarjan do not mention "ternary search trees", 
they use the term "lexicographic search tree".) For a longer discussion,
see Bentley and Sedgewick's paper ["Fast Algorithms for Sorting and 
Searching Strings"][bentley-sedgewick], or their article "Ternary Search
Trees" [in Dr. Dobb's][ternary-search-trees].
   
A _ternary splay tree_, also known as _lexicographic splay tree_, is a
self-adjusting form of ternary search tree. Ternary splay trees are an
extension of Sleator and Tarjan's plain (binary) _splay trees_, and were
first presented in [the same (aforementioned) paper][sleator-tarjan] that
developed and analyzed splay trees. Both varieties of splay trees use the
same restructuring heuristic and have operations with similar amortized
time bounds. 

[sleator-tarjan]: http://www.cs.cmu.edu/~sleator/papers/self-adjusting.pdf "Self-Adjusting Binary Search Trees"

[bentley-sedgewick]: https://www.cs.princeton.edu/~rs/strings/paper.ps "Fast Algorithms for Sorting and Searching Strings"

[ternary-search-trees]: http://www.drdobbs.com/database/ternary-search-trees/184410528 "Ternary Search Trees"