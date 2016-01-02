class MutableBox<Item>(shared variable Item? content) {}

"A mutable [[PrefixMap]] implemented by a _ternary search tree_ 
 whose keys are streams of [[Comparable]] elements. Map entries 
 are mantained in lexicographic order of keys, from the smallest
 to the largest key. The lexicographic ordering of keys relies on 
 comparisons of [[KeyElement]]s, performed either by the method 
 `compare` of the interface [[Comparable]] or by a comparator 
 function specified when the map is created.
 
 Ternary search trees are also known as _lexicographic search trees_.
 For information on such trees, see the documentation of module 
 [`herd.prefixmap`](index.html)."
see (`interface PrefixMap`, `interface Map`, 
     `class Entry`, `interface Comparable`,
     `interface TernaryTreeMap`)
tagged ("Collections")
by ("Francisco Reverbel")
shared class TernarySearchTreeMap<KeyElement, Key, Item> 
        satisfies TernaryTreeMap<KeyElement, Key, Item> 
        given KeyElement satisfies Comparable<KeyElement> 
        given Key satisfies Iterable<KeyElement> {
    
    "A node of this tree. `Node` is a convenient alias for
     `TernaryTreeNode<KeyElement, Item>`."
    see (`class TernaryTreeNode`)
    class Node(KeyElement element) 
            => TernaryTreeNode<KeyElement, Item>(element);
     
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
    
    "The key assembly function, which takes a stream of `KeyElement` 
     instances and returns the corresponding `Key` instance."
    shared actual Key(Iterable<KeyElement>) toKey;
    
    "Creates a new `TernarySplayTreeMap` with the key assembly function
     specified by the parameter `toKey`, with the given `entries` and
     with the comparator function specified by the parameter `compare`." 
    shared new (
        "A key assembly function to be used by this map."
        Key(Iterable<KeyElement>) toKey,
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
        this.toKey = toKey;
    }
    
    "Creates a new `TernarySplayTreeMap` with the same key assembly function,
     entries, and comparator function as the given `TernarySplayTreeMap`."
    shared new copy(TernarySearchTreeMap<KeyElement,Key, Item> sourceMap) {
        entries = {};
        nodeToClone = sourceMap.root;
        compare = sourceMap.compare;
        toKey = sourceMap.toKey;
    }
    
    // initialization of root
    root = if (exists nodeToClone) 
           then nodeToClone.deepCopy() else null;
    
    shared actual Item? put(Key key, Item item) {
        variable Node? node = root;
        variable Node? previousNode = null;
        value keyIterator = key.iterator();
        variable Comparison branch = equal; // whatever
        variable value current = keyIterator.next();
        while (exists n = node, is KeyElement keyElement = current) {
            previousNode = n;
            branch = compare(keyElement, n.element);
            switch (branch)
            case (smaller) { 
                node = n.left;
            }
            case (equal) {
                node = n.middle;
                current = keyIterator.next();
            }
            case (larger) {
                node = n.right;
            }
        }
        if (exists n = previousNode) {
            switch (branch)
            case (smaller) {
                assert (is KeyElement keyElement = current);
                n.left = newVerticalPath(n, keyElement, keyIterator, item);
                return null;  
            }
            case (equal) {
                if (is KeyElement keyElement = current) {
                    "reached the end of a vertical path"
                    assert(!n.middle exists);
                    "any node with no middle child must be terminal"
                    assert(n.terminal);
                    n.middle = newVerticalPath(n, keyElement, 
                                                keyIterator, item);
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
                assert (is KeyElement keyElement = current);
                n.right = newVerticalPath(n, keyElement, keyIterator, item);
                return null;  
            }
        }
        else {
            // The while loop was never entered, 
            // so `current` must still be the first key element
            assert (is KeyElement keyFirst = current);
            root = newVerticalPath(null, keyFirst, keyIterator, item);
            return null;
        }
    }

    // Add initial entries
    for (key->item in entries) {
        put(key, item);
    }
    
    // End of initializer section
    
    shared actual Object? search(Key key)
    {
        variable Node? node = root;
        Iterator<KeyElement> it = key.iterator();
        "a key must be non-empty"
        assert (is KeyElement firstElement = it.next());
        variable KeyElement element = firstElement;
        while (exists n = node) {
            switch (compare(element, n.element))
            case (smaller) {
                node = n.left;
            }
            case (larger) {
                node = n.right;
            }
            case (equal) {
                value next = it.next();
                if (is KeyElement next) {
                    node = n.middle;
                    element = next;
                } 
                else {
                    // we have just looked at the last element of `key`,
                    // and it matched the element in `node`
                    return n;
                }
            }
        }
        return null;
    }
    
    Boolean leaf(Node n)
            => !(n.left exists) && !(n.middle exists) && !(n.right exists);
    
    Node? removeNodes(Node? node, 
                      MutableBox<Item> itemRemoved, 
                      KeyElement keyFirst, 
                      KeyIterator keyRest) {
        if (!exists node) {
            return null;
        }
        else {
            value e = node.element;
            switch (compare(keyFirst, e))
            case (smaller) {
                node.left = removeNodes(node.left, itemRemoved, 
                                        keyFirst, keyRest);
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
                node.right = removeNodes(node.right, itemRemoved, 
                                         keyFirst, keyRest);
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
                if (is KeyElement keyNext = keyRest.next()) {
                    node.middle = removeNodes(node.middle, itemRemoved,
                                              keyNext, keyRest);
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
        value keyIterator = key.iterator();
        assert (is KeyElement keyFirst = keyIterator.next());
        root = removeNodes(root, itemRemoved, keyFirst, keyIterator);
        if (exists r = root) {
            r.parent = null;
        }
        return itemRemoved.content; 
    }
    
    shared actual void clear()
            => root = null;
    
    shared actual TernarySearchTreeMap<KeyElement, Key, Item> createAnotherMap(
        {<Key->Item>*} entries,
        Comparison(KeyElement, KeyElement) compare)
            => TernarySearchTreeMap(toKey, entries, compare);
    
    shared actual TernarySearchTreeMap<KeyElement, Key, Item> clone() 
            => copy(this);
    
    shared actual Boolean equals(Object that)
            => (super of Map<Key, Item>).equals(that);

    shared actual Integer hash
            => (super of Map<Key, Item>).hash;
}
