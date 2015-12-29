"A mutable [[PrefixMap]] implemented by a _ternary splay tree_ 
 whose keys are sequences of [[Comparable]] elements. Map entries 
 are mantained in lexicographic order of keys, from the smallest
 to the largest key. The lexicographic ordering of keys relies on 
 comparisons of [[KeyElement]]s, performed either by the method 
 `compare` of the interface [[Comparable]] or by a comparator 
 function specified when the map is created.

 Ternary splay trees are also known as _lexicographic splay trees_.
 For information on such trees, see the documentation of module 
 [`herd.prefixmap`](index.html)."
see (`interface PrefixMap`, `interface Map`, 
    `class Entry`, `interface Comparable`,
    `interface TernaryTreeMap`)
tagged ("Collections")
by ("Francisco Reverbel")
shared class TernarySplayTreeMap<KeyElement, Item> 
        satisfies TernaryTreeMap<KeyElement, Item> 
        given KeyElement satisfies Comparable<KeyElement> {

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

    variable Node? splayHeader = null;
    
    value exhaustedIterator = 
            object satisfies Iterator<Nothing> {
                next() => finished;
            };

    "Create a new `TernarySplayTreeMap` with the given `entries` and
     the comparator function specified by the parameter `compare`." 
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

    "Create a new `TernarySplayTreeMap` with the same entries and 
     comparator function as the given `TernarySplayTreeMap`."
    shared new copy(TernarySplayTreeMap<KeyElement,Item> sourceMap) {
        entries = {};
        nodeToClone = sourceMap.root;
        compare = sourceMap.compare;
    }

    // initialization of root
    root = if (exists nodeToClone) 
           then nodeToClone.deepCopy() else null;
    
    "A mutable box to be filled out with the results of a call to `splay`."
    class SplayOutputBox() {
        shared variable KeyElement[] remainingKeyElements = [];
        shared variable Node? lastMatchingNode = null;
    }

    "Performs a _ternary splay_ operation in this tree, which is assumed
     to be non empty. Ternary splay is a restructuring operation that searches
     the tree for the longest prefix of the given `key` and rearranjes the 
     nodes in a way that tends to improve tree balancing and, at the same
     time, places that longest prefix in a vertical middle chain whose first
     node is the root of the tree. As a result of splaying, the node with first
     element of the longest `key`prefix becomes `root`, the node with the
     second element (if it exists) becomes middle child of `root`, the node 
     with the third element (if it exists) becomes middle grandchild of `root`,
     and so on. "
    void splay(
        "The key whose longest prefix will be moved to a vertical middle chain
         starting at the root."
        Key key, 
        "If `outBox` exists, it is updated as follows: 
         - The field `remainingKeyElements` gets a (possibly empty) sequence 
           with the unmatched key tail, that is, with the tailing elements of 
           `key` that are not part of the longest `key` prefix within this
           tree.
         - The field `lastMatchingNode` gets the (possibly `null`) last node
           of the vertical middle chain with the longest `key` prefix."
        SplayOutputBox? outBox = null) {
        // Ternary splaying is implemented as a sequence of plain 
        // _binary splaying_ operations, one per element of the `key` prefix
        // found in the tree. Each binary splaying operation is performed on 
        // the _binary_ subtree that may contain the next element. If this 
        // element is found, binary splaying moves it to the root of its 
        // binary subtree. The sequence of binary splaying operations ends
        // when some key element is not found, of when the last `key` 
        // element is moved to the root of its binary subtree.
        //
        // Each binary splaying operation uses Sleator and Tarjan's
        // "top-down splaying" procedure, which is discussed in
        // http://www.cs.cmu.edu/~sleator/papers/self-adjusting.pdf
        variable Node l;
        variable Node r; 
        variable Node? lastMatchingNode = null;
        variable Key k = key;
        variable KeyElement[] keyRest = key;
        variable Boolean keyElementFound;
        if (exists box = outBox) {
            box.remainingKeyElements = key;
            box.lastMatchingNode = null;
        }
        if (splayHeader is Null) {
            // Late initialization of the auxiliary node `splayHeader`. 
            // The key element stored in this node is completely irrelevant.
            // Even so, the node must have _some_ key element within itself.
            // So we postponed the creation of `splayHeader` until we had 
            // some instance of `KeyElement` at hand. 
            splayHeader = Node(key.first);
        }
        assert (exists header = splayHeader);
        assert (exists rootNode = root);
        variable Node curNode = rootNode;
        // The outer loop below iterates over `key` elements. Its body does 
        // a top-down splay on the _binary_ subtree that may contain the next
        // key element (`k.first`). The body of the outer loop is based on 
        // Danny Sleator's Java code for top-down splaying, available at 
        // http://www.link.cs.cmu.edu/link/ftp-site/splaying/SplayTree.java.
        while (true) {
            l = header;
            r = header;
            header.left = null;  
            header.right = null;
            keyElementFound = false;
            while (true) {
                switch (compare(k.first, curNode.element))
                case (smaller) {
                    if (exists curLeft = curNode.left) {
                        variable Node nextNode = curLeft;
                        if (compare(k.first, curLeft.element) == smaller) {
                            // rotate right
                            curNode.left = curLeft.right;
                            if (exists n = curLeft.right) {
                                n.parent = curNode;
                            }
                            curLeft.right = curNode;
                            value curNodeParent = curNode.parent;
                            curNode.parent = curLeft;
                            curLeft.parent = curNodeParent;
                            curNode = curLeft;
                            if (exists leftChild = curNode.left) { 
                                nextNode = leftChild;
                            }
                            else {
                                break;
                            }
                        }
                        // link right
                        r.left = curNode;
                        curNode.parent = r;
                        r = curNode;
                        curNode = nextNode;
                    }
                    else {
                        break;
                    }
                }
                case (equal) {
                    keyElementFound = true;
                    break;
                }
                case (larger) {
                    if (exists curRight = curNode.right) {
                        variable Node nextNode = curRight;
                        if (compare(k.first, curRight.element) == larger) {      
                            // rotate left
                            curNode.right = curRight.left;
                            if (exists n = curRight.left) {
                                n.parent = curNode;
                            }
                            curRight.left = curNode;
                            value curNodeParent = curNode.parent;
                            curNode.parent = curRight;
                            curRight.parent = curNodeParent;
                            curNode = curRight;
                            if (exists rightChild = curNode.right) {
                                nextNode = rightChild;
                            }
                            else {
                                break;
                            }
                        }
                        // link left
                        l.right = curNode;
                        curNode.parent = l;
                        l = curNode;
                        curNode = nextNode;
                    }
                    else {
                        break;
                    }
                }
            }
            // assemble
            l.right = curNode.left;
            if (exists n = curNode.left) {
                n.parent = l;
            }
            r.left = curNode.right;
            if (exists n = curNode.right) {
                n.parent = r;
            }
            curNode.left = header.right;
            if (exists n = header.right) {
                n.parent = curNode;
            }
            curNode.right = header.left;
            if (exists n = header.left) {
                n.parent = curNode;
            }
            if (exists n = lastMatchingNode) {
                n.middle = curNode;
                curNode.parent = n;
            }
            else {
                root = curNode;
                curNode.parent = null;
            }
            // bottom of outer loop
            if (keyElementFound) {
                keyRest = k.rest;
                lastMatchingNode = curNode;
                if (nonempty rest = keyRest, exists m = curNode.middle) {
                    k = rest;
                    curNode = m;
                }
                else {
                    break;
                }
            }
            else {
                break;
            }
        }
        if (exists box = outBox) {
            box.remainingKeyElements = keyRest;
            box.lastMatchingNode = lastMatchingNode;
        }
    }

    "A mutable box to be filled out with the results of a call to `splay`."
    class SplayByIterableKeyOutputBox() {
        shared variable Iterator<KeyElement> remainingKeyElements = 
                exhaustedIterator;
        shared variable Node? lastMatchingNode = null;
    }

    "Performs a _ternary splay_ operation in this tree, which is assumed
     to be non empty. Ternary splay is a restructuring operation that searches
     the tree for the longest prefix of the given `key` and rearranjes the 
     nodes in a way that tends to improve tree balancing and, at the same
     time, places that longest prefix in a vertical middle chain whose first
     node is the root of the tree. As a result of splaying, the node with first
     element of the longest `key`prefix becomes `root`, the node with the
     second element (if it exists) becomes middle child of `root`, the node 
     with the third element (if it exists) becomes middle grandchild of `root`,
     and so on. "
    void splayByIterableKey(
        "The key whose longest prefix will be moved to a vertical middle chain
         starting at the root."
        IterableKey key, 
        "If `outBox` exists, it is updated as follows: 
         - The field `remainingKeyElements` gets a (possibly empty) sequence 
           with the unmatched key tail, that is, with the tailing elements of 
           `key` that are not part of the longest `key` prefix within this
           tree.
         - The field `lastMatchingNode` gets the (possibly `null`) last node
           of the vertical middle chain with the longest `key` prefix."
        SplayByIterableKeyOutputBox? outBox = null) {
        // Ternary splaying is implemented as a sequence of plain 
        // _binary splaying_ operations, one per element of the `key` prefix
        // found in the tree. Each binary splaying operation is performed on 
        // the _binary_ subtree that may contain the next element. If this 
        // element is found, binary splaying moves it to the root of its 
        // binary subtree. The sequence of binary splaying operations ends
        // when some key element is not found, of when the last `key` 
        // element is moved to the root of its binary subtree.
        //
        // Each binary splaying operation uses Sleator and Tarjan's
        // "top-down splaying" procedure, which is discussed in
        // http://www.cs.cmu.edu/~sleator/papers/self-adjusting.pdf
        variable Node l;
        variable Node r; 
        variable Node? lastMatchingNode = null;
        variable Boolean keyElementFound;
        
        Iterator<KeyElement> it = key.iterator();
        "a key must be non-empty"
        assert (is KeyElement firstElement = it.next());
        variable KeyElement element = firstElement;

        if (exists box = outBox) {
            box.remainingKeyElements = key.iterator();
            box.lastMatchingNode = null;
        }
        if (splayHeader is Null) {
            // Late initialization of the auxiliary node `splayHeader`. 
            // The key element stored in this node is completely irrelevant.
            // Even so, the node must have _some_ key element within itself.
            // So we postponed the creation of `splayHeader` until we had 
            // some instance of `KeyElement` at hand. 
            splayHeader = Node(element);
        }
        assert (exists header = splayHeader);
        assert (exists rootNode = root);
        variable Node curNode = rootNode;
        // The outer loop below iterates over `key` elements. Its body does 
        // a top-down splay on the _binary_ subtree that may contain the next
        // key element (`k.first`). The body of the outer loop is based on 
        // Danny Sleator's Java code for top-down splaying, available at 
        // http://www.link.cs.cmu.edu/link/ftp-site/splaying/SplayTree.java.
        while (true) {
            l = header;
            r = header;
            header.left = null;  
            header.right = null;
            keyElementFound = false;
            while (true) {
                switch (compare(element, curNode.element))
                case (smaller) {
                    if (exists curLeft = curNode.left) {
                        variable Node nextNode = curLeft;
                        if (compare(element, curLeft.element) == smaller) {
                            // rotate right
                            curNode.left = curLeft.right;
                            if (exists n = curLeft.right) {
                                n.parent = curNode;
                            }
                            curLeft.right = curNode;
                            value curNodeParent = curNode.parent;
                            curNode.parent = curLeft;
                            curLeft.parent = curNodeParent;
                            curNode = curLeft;
                            if (exists leftChild = curNode.left) { 
                                nextNode = leftChild;
                            }
                            else {
                                break;
                            }
                        }
                        // link right
                        r.left = curNode;
                        curNode.parent = r;
                        r = curNode;
                        curNode = nextNode;
                    }
                    else {
                        break;
                    }
                }
                case (equal) {
                    keyElementFound = true;
                    break;
                }
                case (larger) {
                    if (exists curRight = curNode.right) {
                        variable Node nextNode = curRight;
                        if (compare(element, curRight.element) == larger) {      
                            // rotate left
                            curNode.right = curRight.left;
                            if (exists n = curRight.left) {
                                n.parent = curNode;
                            }
                            curRight.left = curNode;
                            value curNodeParent = curNode.parent;
                            curNode.parent = curRight;
                            curRight.parent = curNodeParent;
                            curNode = curRight;
                            if (exists rightChild = curNode.right) {
                                nextNode = rightChild;
                            }
                            else {
                                break;
                            }
                        }
                        // link left
                        l.right = curNode;
                        curNode.parent = l;
                        l = curNode;
                        curNode = nextNode;
                    }
                    else {
                        break;
                    }
                }
            }
            // assemble
            l.right = curNode.left;
            if (exists n = curNode.left) {
                n.parent = l;
            }
            r.left = curNode.right;
            if (exists n = curNode.right) {
                n.parent = r;
            }
            curNode.left = header.right;
            if (exists n = header.right) {
                n.parent = curNode;
            }
            curNode.right = header.left;
            if (exists n = header.left) {
                n.parent = curNode;
            }
            if (exists n = lastMatchingNode) {
                n.middle = curNode;
                curNode.parent = n;
            }
            else {
                root = curNode;
                curNode.parent = null;
            }
            // bottom of outer loop
            if (keyElementFound) {
                if (exists box = outBox) {
                    box.remainingKeyElements.next();
                }
                lastMatchingNode = curNode;
                value next = it.next();
                if (is KeyElement next, exists m = curNode.middle) {
                    element = next;
                    curNode = m;
                }
                else {
                    break;
                }
            }
            else {
                break;
            }
        }
        if (exists box = outBox) {
            box.lastMatchingNode = lastMatchingNode;
        }
    }
    
    "Links to the given `parent` node a vertical chain of middle descendents
     containing the elements of the given `key`. The first element of `key`
     gets stored in a newly created node that becomes middle child of
     `parent`, the second element (if it exists) gets stored in a newly
     created node that becomes middle grandchild of `parent`, and so on.
     The given `item` gets stored in the last node of the vertical chain,
     which is marked as a terminal node."
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
        if (root exists) {
            value box = SplayOutputBox(); 
            splay(key, box);
            if (nonempty keySuffix = box.remainingKeyElements) {
                Node newSubtree = newVerticalPath(null, keySuffix, item);
                Node curNode;
                if (exists node = box.lastMatchingNode) {
                    if (exists m = node.middle) {
                        curNode = m;
                    }
                    else {
                        node.middle = newSubtree;
                        newSubtree.parent = node;
                        return null;
                    }
                }
                else {
                    assert (exists r = root);
                    curNode = r;
                }
                switch (compare(keySuffix.first, curNode.element))
                case (smaller) {
                    newSubtree.left = curNode.left;
                    if (exists n = curNode.left) {
                        n.parent = newSubtree;
                    }
                    newSubtree.right = curNode;
                    curNode.parent = newSubtree;
                    curNode.left = null;
                }
                case (larger) {
                    newSubtree.right = curNode.right;
                    if (exists n = curNode.right) {
                        n.parent = newSubtree;
                    }
                    newSubtree.left = curNode;
                    curNode.parent = newSubtree;
                    curNode.right = null;
                }
                case (equal) {
                    "this point should never be reached"
                    assert (false);
                }
                if (exists node = box.lastMatchingNode) {
                    node.middle = newSubtree;
                    newSubtree.parent = node;
                }
                else {
                    root = newSubtree;
                    newSubtree.parent = null;
                }
                return null;
            }
            else {
                assert (exists node = box.lastMatchingNode);
                if (node.terminal) {
                    value oldItem = node.item;
                    node.item = item;
                    return oldItem;
                }
                else {
                    node.item = item;
                    node.terminal = true;
                    return null;
                }
            }
        }
        else {
            root = newVerticalPath(null, key, item);
            return null;
        }
    }

    //-------------------------------------------------------------------------

    // Add initial entries
    for (key->item in entries) {
        put(key, item);
    }

    // End of initializer section

    shared actual Object? search(Key key) {
        if (root exists) {
            value box = SplayOutputBox(); 
            splay(key, box);
            if (box.remainingKeyElements.empty) { 
                //assert (box.lastMatchingNode exists);
                return box.lastMatchingNode;  
            }
            else {
                return null;
            }
        }
        else {
            return null;
        }
    }
    
    shared actual Object? searchByIterableKey(IterableKey key)
    {
        if (root exists) {
            value box = SplayByIterableKeyOutputBox(); 
            splayByIterableKey(key, box);
            if (box.remainingKeyElements.next() is Finished) { 
                //assert (box.lastMatchingNode exists);
                return box.lastMatchingNode;  
            }
            else {
                return null;
            }
        }
        else {
            return null;
        }
    }
    
    "Removes the given `node` and puts one of its child nodes
     (the given `childNode`) in its place."
    void childNodeReplacesItsParent(Node? childNode, Node node) {
        if (exists p = node.parent) {
            if (exists pl = p.left, pl === node) {
                p.left = childNode;
            }
            else if (exists pm = p.middle, 
                     pm === node) {
                     p.middle = childNode;
            }
            else {
                assert (exists pr = p.right,
                        pr === node);
                p.right = childNode;
            }
            if (exists theChild = childNode) {
                theChild.parent = p;
            }
        }
        else {
            root = childNode;
            if (exists theChild = childNode) {
                theChild.parent = null;
            }
        }
    }

    shared actual Item? remove(Key key) {
        if (root exists) {
            value box = SplayOutputBox(); 
            splay(key, box);
            if (box.remainingKeyElements.empty, 
                    exists node = box.lastMatchingNode,
                    node.terminal) {
                variable Node curNode = node;
                assert (is Item theItem = node.item);
                curNode.item = null;
                curNode.terminal = false;
                while (!curNode.terminal && !curNode.middle exists) {
                    if (exists curLeft = curNode.left) {
                        if (exists curRight = curNode.right) {
                            // both the left and the right child exist:
                            // join the child subtrees together, creating
                            // a subtree that will take the place of 
                            // `curNode`. We have arbitrarily chosen to put 
                            // the right subtree under the left subtree.
                            //  (The other way around would also work.)
                            Node descendRightmostBranch(Node n)
                                    => if (exists rc = n.right)
                                       then descendRightmostBranch(rc)
                                       else n;
                            value n = descendRightmostBranch(curLeft);
                            n.right = curRight;
                            curRight.parent = n; 
                            // `curLeft` takes the place of `curNode`
                            childNodeReplacesItsParent(curLeft, curNode);
                            break; // `curNode = curLeft;` also works here
                            
                        }
                        else {
                            // only the left child exists:
                            // the left child takes the place of `curNode`
                            childNodeReplacesItsParent(curLeft, curNode);
                            break; // `curNode = curLeft;` also works here
                        }
                    }
                    else { 
                        if (exists curRight = curNode.right) {
                            // only the right child exists:
                            // the right child will replace `curNode`
                            childNodeReplacesItsParent(curRight, curNode);
                            break; // `curNode = curRight;` also works here
                            
                        }
                        else {
                            // `curNode` is a non-terminal leaf node:
                            // nobody will take its place
                            childNodeReplacesItsParent(null, curNode);
                            if (exists p = curNode.parent) {
                                curNode = p; // proceed at the parent node
                            }
                            else {
                                break;
                            }
                        }
                    }
                }
                return theItem;
            }
            else {
                // there are unmatched key elements 
                // (`remainingKeyElements` is non empty)
                return null;
            }
        }
        else {
            // `root` does not exist
            return null;
        }
    }

    shared actual void clear()
            => root = null;
    
    shared actual TernarySplayTreeMap<KeyElement, Item> createAnotherMap(
        {<Key->Item>*} entries,
        Comparison(KeyElement, KeyElement) compare)
            => TernarySplayTreeMap(entries, compare);
    
    shared actual TernarySplayTreeMap<KeyElement, Item> clone() 
            => copy(this);
    
    shared actual Boolean equals(Object that)
            => (super of Map<Key, Item>).equals(that);
    
    shared actual Integer hash
            => (super of Map<Key, Item>).hash;
}