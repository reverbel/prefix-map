class MutableBox<Item>(shared variable Item? content) {}

"""A mutable [[PrefixMap]] implemented using a _ternary search tree_ 
   whose keys are sequences of [[Comparable]] elements. Map entries 
   are mantained in lexicographic order of keys, from the smallest
   to the largest key. The lexicographig ordering of keys relies on 
   comparisons of [[KeyElement]]s, performed either by the method 
   `compare` of the interface [[Comparable]] or by a comparator 
   function specified when the map is created.
 
   Ternary search trees are also known as _lexicographic search trees_.
   For information on such trees, see the documentation of interface
   [[TernaryTreeMap]]."""
see (`interface PrefixMap`, `interface Map`, 
     `class Entry`, `interface Comparable`,
     `interface TernaryTreeMap`)
tagged ("Collections")
by ("Francisco Reverbel")
shared class TernarySearchTreeMap<KeyElement, Item> 
        satisfies TernaryTreeMap<KeyElement, Item> 
        given KeyElement satisfies Comparable<KeyElement> {
    
    "A node of this tree. `Node` is a convenient alias for
     `TreeNode<KeyElement, Item>`."
    see (`class TreeNode`)
    class Node(KeyElement element) 
            => TreeNode<KeyElement, Item>(element);
     
    "The root node of the tree."
    variable Node? root = null;
    
    shared actual Object? rootNode
            => root;
    
    "The initial entries in the map."
    {<Key->Item>*} entries;
    
    "Alternatively, the root node of a tree to clone."
    Node? nodeToClone;
    
    "A comparator function used to sort the entries."
    shared actual Comparison(KeyElement, KeyElement) compare;
    
    "Create a new `TernarySearchTreeMap` with the given `entries` and the 
     comparator function specified by the parameter `compare`." 
    shared new (
        "The initial entries in the map. If `entries` is absent,
         an empty map will be created. "
        {<Key->Item>*} entries = {},
        "A function used to compare key elements.
         If `compare` is absent, the comparator method of interface
         [[Comparable]] will be used to compare `KeyElement`s."
        Comparison(KeyElement, KeyElement) compare = 
                (KeyElement x, KeyElement y) => x.compare(y)) {
        this.entries = entries;
        nodeToClone = null;
        this.compare = compare;
    }
    
    "Create a new `TernarySearchTreeMap` with the same entries and 
     comparator function as the given `TernarySearchTreeMap`."
    shared new copy(TernarySearchTreeMap<KeyElement,Item> sourceMap) {
        entries = {};
        nodeToClone = sourceMap.root;
        compare = sourceMap.compare;
    }
    
    // initialization of root
    root = if (exists nodeToClone) 
           then nodeToClone.deepCopy() else null;
    
    
    Node newVerticalPath(Node? parent, Key key, Item item) {
        variable KeyElement e = key.first;
        variable KeyElement[] rest = key.rest;
        value head = Node(e);
        head.parent = parent;
        variable Node node = head; 
        while (nonempty toCopy = rest) {
            e = toCopy.first;
            rest = toCopy.rest;
            value newNode = Node(e);
            newNode.parent = node;
            node.middle = newNode;
            node = newNode;
        }
        // node received the last element of the key:
        // store item in it and mark it as terminal
        node.item = item;
        node.terminal = true;
        return head;
    }
    
    shared actual Item? put(Key key, Item item) {
        variable Node? node = root;
        variable Node? previousNode = null;
        variable KeyElement[] keySuffix = key; 
        variable Comparison branch = equal; // whatever
        while (exists n = node, nonempty suffix = keySuffix) {
            previousNode = n;
            branch = compare(suffix.first, n.element);
            switch (branch)
            case (smaller) { 
                node = n.left;
            }
            case (equal) {
                node = n.middle;
                keySuffix = suffix.rest;
            }
            case (larger) {
                node = n.right;
            }
        }
        if (exists n = previousNode) {
            switch (branch)
            case (smaller) {
                assert(nonempty suffix = keySuffix); 
                n.left = newVerticalPath(n, suffix, item);
                return null;  
            }
            case (equal) {
                if (nonempty suffix = keySuffix) {
                    "reached the end of a vertical path"
                    assert(!n.middle exists);
                    "any node with no middle child must be terminal"
                    assert(n.terminal);
                    n.middle = newVerticalPath(n, suffix, item);
                    return null;
                }
                else if (!n.terminal) {
                    n.item = item;
                    n.terminal = true;
                    return null;
                }
                else {
                    value oldItem = n.item;
                    n.item = item;
                    return oldItem;
                }
            }
            case (larger) {
                assert(nonempty suffix = keySuffix); 
                n.right = newVerticalPath(n, suffix, item);
                return null;  
            }
        }
        else {
            root = newVerticalPath(null, key, item);
            return null;
        }
    }

    // Add initial entries
    for (key->item in entries) {
        put(key, item);
    }
    
    // End of initializer section
    
    Node? recursiveSearch(Key key, Node? node) {
        if (!exists node) {
            return null; 
        }
        else { 
            switch (compare(key.first, node.element))
            case (smaller) { 
                return recursiveSearch(key, node.left); 
            } 
            case (larger) {
                return recursiveSearch(key, node.right); 
            }
            case (equal) {
                if (nonempty rest = key.rest) {
                    return recursiveSearch(rest, node.middle); 
                }
                else {
                    // the last element of `key` matched the one in `node`
                    return node;
                }
            }
        }
    }
    
    shared actual Object? search(Key key)
            => recursiveSearch(key, root);
    
   /*
    //Iterative version of lookup
    Node? lookup(Key key, Node? startingNode = root) {
        variable Node? node = startingNode;
        variable Key k = key;
        while (exists n = node) {
            switch (compare(k.first, n.element))
            case (smaller) {
                node = n.left;
            }
            case (larger) {
                node = n.right;
            }
            case (equal) {
                if (nonempty rest = k.rest) {
                    node = n.middle;
                    k = rest;
                }
                else {
                    // we have just looked at the last element of `key`,
                    // and it matched the element in `node`
                    return if (n.terminal) then n else null;
                }
            }
        }
        return null;
    }
    */
   
    Boolean leaf(Node n)
            => !(n.left exists) && !(n.middle exists) && !(n.right exists);
    
    Node? removeNodes(Node? node, MutableBox<Item> itemRemoved, Key key) {
        if (!exists node) {
            return null;
        }
        else {
            value e = node.element;
            value first = key.first;
            switch (compare(first, e))
            case (smaller) {
                node.left = removeNodes(node.left, itemRemoved, key);
                if (exists left = node.left) {
                    left.parent = node;
                    return node;
                }
                else if (!node.terminal && !(node.middle exists)
                                        && !(node.right exists)) {
                    return null; // prune non-terminal leaf node
                }
                else {
                    return node;
                }
            }
            case (larger) {
                node.right = removeNodes(node.right, itemRemoved, key);
                if (exists right = node.right) {
                    right.parent = node;
                    return node;
                }
                else if (!node.terminal && !(node.left exists) 
                                        && !(node.middle exists)) {
                    return null; // prune non-terminal leaf node
                }
                else {
                    return node;
                }
            }
            case (equal) {
                if (nonempty rest = key.rest) {
                    node.middle = removeNodes(node.middle, itemRemoved, rest);
                    if (exists middle = node.middle) {
                        middle.parent = node;
                    }
                    
                    Node? retNode; // The node to be returned by this method
                    // If `node` remains in the tree, `retNode` will be 
                    // `node`. Otherwise, `retNode` will be either null
                    // or a node that takes the place of `node`.
                    
                    if (!node.terminal && !(node.middle exists)) {
                        // prune non-terminal nodes with no middle child 
                        if (exists l = node.left, 
                            exists r = node.right) {
                            // The node to be pruned has two child nodes:
                            // join the child subtrees together, creating
                            // a subtree that will take the place of the
                            // vanishing node. We have arbitrarily chosen 
                            // to put the r subtree under the l subtree.
                            //  (The other way around would also work.)
                            Node descendRightmostBranch(Node n)
                                    => if (exists rc = n.right)
                                       then descendRightmostBranch(rc)
                                       else n;
                            value n = descendRightmostBranch(l);
                            n.right = r;
                            r.parent = n; 
                            retNode = l;
                        }
                        else if (!(node.left exists)) {
                            // right child will replace `node`
                            retNode = node.right; // possibly null
                        }
                        else { // (!(node.right exists))
                            // left child will replace `node`
                            retNode = node.left;
                        }
                    }
                    else {
                        // `node` remains in the tree
                        retNode = node;
                    }
                    return retNode;
                }
                else {
                    // `node` has the last element of the key
                    // is it a terminal node?
                    if (node.terminal) {
                        // yes: 
                        // mark it as non terminal, 
                        // effectively removing  the given `key` from the tree
                        node.terminal = false;
                        // retrieve the value no longer 
                        // associated with the given `key` 
                        Item? removedItem = node.item;
                        assert(is Item removedItem);
                        itemRemoved.content = removedItem;
                        if (leaf(node)) {
                            // `node` is a leaf: remove it
                            return null; 
                        }
                        else {
                            // current node is not a leaf node, 
                            // so it must remain in the tree
                            return node; 
                        }
                    }
                    else {
                        // no: 
                        // cannot remove anything
                        "a non-terminal node cannot be a leaf node"
                        assert(!leaf(node));
                        return node;
                    }
                }
            }
        }
    }
    
    shared actual Item? remove(Key key) {
        value itemRemoved = MutableBox<Item> {
            content = null;
        };
        root = removeNodes(root, itemRemoved, key);
        if (exists r = root) {
            r.parent = null;
        }
        return itemRemoved.content; 
    }
    
    shared actual void clear()
            => root = null;
    
    shared actual TernarySearchTreeMap<KeyElement,Item> measure(Key from, 
                                                          Integer length)
            => TernarySearchTreeMap(higherEntries(from).take(length), compare);
    
    shared actual TernarySearchTreeMap<KeyElement,Item> span(Key from, Key to)
            => let (reverse = compareKeys(from,to)==larger)
                TernarySearchTreeMap { 
                    entries = reverse then descendingEntries(from,to) 
                                      else ascendingEntries(from,to);
                    compare(KeyElement x, KeyElement y) 
                            => reverse then compare(y,x)
                                       else compare(x,y); 
    };
    
    shared actual TernarySearchTreeMap<KeyElement,Item> spanFrom(Key from)
            => TernarySearchTreeMap(higherEntries(from), compare);
    
    shared actual TernarySearchTreeMap<KeyElement,Item> spanTo(Key to)     
            => TernarySearchTreeMap(
                    takeWhile((entry) => compareKeys(entry.key,to) != larger), 
                    compare);
    
    shared actual TernarySearchTreeMap<KeyElement, Item> clone() 
            => copy(this);
    
    shared actual Boolean equals(Object that)
            => (super of TernaryTreeMap<KeyElement, Item>).equals(that);

    shared actual Integer hash
            => (super of TernaryTreeMap<KeyElement, Item>).hash;
}
