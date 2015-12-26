"A mutable [[PrefixMap]] implemented by a _ternary splay tree_ 
 whose keys are sequences of [[Comparable]] elements. Map entries 
 are mantained in lexicographic order of keys, from the smallest
 to the largest key. The lexicographic ordering of keys relies on 
 comparisons of [[KeyElement]]s, performed either by the method 
 `compare` of the interface [[Comparable]] or by a comparator 
 function specified when the map is created.

 Ternary splay trees are also known as _lexicographic splay trees_.
 For information on such trees, see the documentation of module 
 [`herd.reverbel.prefixmap`](index.html)."
see (`interface PrefixMap`, `interface Map`, 
    `class Entry`, `interface Comparable`,
    `interface TernaryTreeMap`)
tagged ("Collections")
by ("Francisco Reverbel")
shared class TernarySplayTreeMap<KeyElement, Item> 
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
    
    class SplayOutputBox() {
        shared variable KeyElement[] remainingKeyElements = [];
        shared variable Node? lastMatchingNode = null;
    }

    void splay(Key key, SplayOutputBox? outputBox = null) {
        variable Node l;
        variable Node r; 
        variable Node? lastMatchingNode = null;
        variable Key k = key;
        variable KeyElement[] keyRest = key;
        variable Boolean keyElementFound;
        if (exists box = outputBox) {
            box.remainingKeyElements = key;
            box.lastMatchingNode = null;
        }
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
        if (exists box = outputBox) {
            box.remainingKeyElements = keyRest;
            box.lastMatchingNode = lastMatchingNode;
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
            value outBox = SplayOutputBox(); 
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

    // Removes the given `node` and puts one of its child nodes
    // (the given `childNode`) in its place.
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