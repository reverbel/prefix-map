shared class TernarySplayTreeMap<KeyElement, Item> 
        extends AbstractTernaryTree<KeyElement, Item> 
        given KeyElement satisfies Comparable<KeyElement> {
    
    "The root node of the tree."
    shared actual variable Node? root;
    
    "The initial entries in the map."
    shared {<Key->Item>*} entries;
    
    "Alternatively, the root node of a tree to clone."
    shared Node? nodeToClone;
    
    "A comparator function used to sort the entries."
    shared actual Comparison(KeyElement, KeyElement) compare;
    
    variable Node? auxNode = null;
    
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
                (KeyElement x, KeyElement y) => x.compare(y)
    ) extends AbstractTernaryTree<KeyElement, Item>() {
        this.entries = entries;
        nodeToClone = null;
        this.compare = compare;
    }
    
    "Create a new `TernarySplayTreeMap` with the same entries and 
     comparator function as the given `TernarySplayTreeMap`."
    shared new copy(TernarySplayTreeMap<KeyElement,Item> abstractTernaryTree)
            extends AbstractTernaryTree<KeyElement, Item>() {
        entries = {};
        nodeToClone = abstractTernaryTree.root;
        compare = abstractTernaryTree.compare;
    }
    
    // initialization of root
    root = if (exists nodeToClone) 
           then nodeToClone.deepCopy() else null;

    class SplayOutputBox(Key key) {
        shared variable Node? lastMatchingNode = null;
        shared variable KeyElement[] remainingKeyElements = key;
    }
    
    void splay(Key key, SplayOutputBox? outputBox = null) {
        variable Node l;
        variable Node r; 
        variable Node? lastMatchingNode = null;
        variable Key k = key;
        variable KeyElement[] keyRest = key;
        variable Boolean keyElementFound;
        if (!auxNode exists) {
            auxNode = Node(key.first);
        }
        assert (exists aux = auxNode);
        assert (exists rootNode = root);
        variable Node curNode = rootNode; 
        while (true) {
            l = aux;
            r = aux;
            aux.left = null;  
            aux.right = null;
            keyElementFound = false;
            while (true) {
                switch (compare(k.first, curNode.element))
                case (smaller) {
                    if (exists nextNode = curNode.left) {
                        if (compare(k.first, nextNode.element) == smaller) {
                            // rotate right
                            curNode.left = nextNode.right;
                            if (exists n = nextNode.right) {
                                n.parent = curNode;
                            }
                            nextNode.right = curNode;
                            value curNodeParent = curNode.parent;
                            curNode.parent = nextNode;
                            nextNode.parent = curNodeParent;
                            curNode = nextNode;
                            if (!curNode.left exists) { 
                                break; 
                            }
                        }
                        // link right
                        r.left = curNode;
                        curNode.parent = r;
                        r = curNode;
                        assert (exists leftChild = curNode.left);
                        curNode = leftChild;
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
                    if (exists nextNode = curNode.right) {
                        if (compare(k.first, nextNode.element) == larger) {      
                            // rotate left
                            curNode.right = nextNode.left;
                            if (exists n = nextNode.left) {
                                n.parent = curNode;
                            }
                            nextNode.left = curNode;
                            value curNodeParent = curNode.parent;
                            curNode.parent = nextNode;
                            nextNode.parent = curNodeParent;
                            curNode = nextNode;
                            if (!curNode.right exists) {
                                break; 
                            }
                        }
                        // link left
                        l.right = curNode;
                        curNode.parent = l;
                        l = curNode;
                        assert (exists rightChild = curNode.right);
                        curNode = rightChild;
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
            curNode.left = aux.right;
            if (exists n = aux.right) {
                n.parent = curNode;
            }
            curNode.right = aux.left;
            if (exists n = aux.left) {
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
            // bottom of inner loop
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
        if (exists outBox = outputBox) {
            outBox.remainingKeyElements = keyRest;
            outBox.lastMatchingNode = lastMatchingNode;
        }
    }
    
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
            value outBox = SplayOutputBox(key); 
            splay(key, outBox);
            if (nonempty keySuffix = outBox.remainingKeyElements) {
                Node newSubtree = newVerticalPath(null, keySuffix, item);
                Node curNode;
                if (exists node = outBox.lastMatchingNode) {
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
                if (exists node = outBox.lastMatchingNode) {
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
                assert (exists node = outBox.lastMatchingNode);
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
    
    shared actual Node? search(Key key, Node? node) {
        if (!exists node) {
            return null; 
        }
        else { 
            switch (compare(key.first, node.element))
            case (smaller) { 
                return search(key, node.left); 
            } 
            case (larger) {
                return search(key, node.right); 
            }
            case (equal) {
                if (nonempty rest = key.rest) {
                    return search(rest, node.middle); 
                }
                else {
                    // the last element of `key` matched the one in `node`
                    return node;
                }
            }
        }
    }
    
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
    
    //-------------------------------------------------------------------------
    
    shared actual TernarySplayTreeMap<KeyElement,Item> measure(Key from, 
                                                               Integer length)
            => TernarySplayTreeMap(higherEntries(from).take(length), compare);
    
    shared actual TernarySplayTreeMap<KeyElement,Item> span(Key from, Key to)
            => let (reverse = compareKeys(from,to)==larger)
                TernarySplayTreeMap { 
                    entries = reverse then descendingEntries(from,to) 
                                      else ascendingEntries(from,to);
                    compare(KeyElement x, KeyElement y) 
                            => reverse then compare(y,x)
                                       else compare(x,y); 
    };
    
    shared actual TernarySplayTreeMap<KeyElement,Item> spanFrom(Key from)
            => TernarySplayTreeMap(higherEntries(from), compare);
    
    shared actual TernarySplayTreeMap<KeyElement,Item> spanTo(Key to)     
            => TernarySplayTreeMap(
                    takeWhile((entry) => compareKeys(entry.key,to) != larger), 
                    compare);
    
    shared actual TernarySplayTreeMap<KeyElement, Item> clone() 
            => copy(this);


    //shared actual Item? put(Key key, Item item) => nothing;
    
    //shared actual Item? remove(Key key) => nothing;
    
    //shared actual Node? search(Key key, Node? node) => nothing;
    
     
}