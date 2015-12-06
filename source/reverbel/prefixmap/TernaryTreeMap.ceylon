import ceylon.collection {
    MutableMap,
    MutableList,
    ArrayList
}

class TernaryTreeMap<KeyElement, Item> 
        satisfies PrefixMap<KeyElement, Item> 
                  & MutableMap<[KeyElement+], Item> 
        given KeyElement satisfies Comparable<KeyElement> {
    
    class Node(shared KeyElement element,
        shared variable Item? item, 
        shared variable Node? leftChild,
        shared variable Node? middleChild,
        shared variable Node? rightChild,
        shared variable Boolean terminal) {
        
        shared Node deepCopy() {
            value copy = Node {
                element = this.element;
                item = this.item;
                leftChild = null;
                middleChild = null;
                rightChild = null;
                terminal = this.terminal;
            };
            if (exists l = leftChild) {
                copy.leftChild = l.deepCopy();
            }
            if (exists m = middleChild) {
                copy.middleChild = m.deepCopy();
            }
            if (exists r = rightChild) {
                copy.rightChild = r.deepCopy();
            }
            return copy;
        }
    }
    
    "The root node of the tree."
    variable Node? root;
    
    "The initial entries in the map."
    {<Key->Item>*} entries;
    
    "Alternatively, a node to clone."
    Node? nodeToClone;
        
    "Create a new `TernaryTreeMap` with the given [[entries]]."
    shared new (
        "The initial entries in the map."
        {<Key->Item>*} entries = {}) {
        this.entries = entries;
        nodeToClone = null;
    }
    
    "Create a new `TernaryTreeMap` with the same entries as the
     given [[ternaryTreeMap]]."
    shared new copy(TernaryTreeMap<KeyElement,Item> ternaryTreeMap) {
        entries = {};
        nodeToClone = ternaryTreeMap.root;
    }
    
    root = if (exists nodeToClone) 
           then nodeToClone.deepCopy() else null;
    
    [Node, Item?] insert(Node? curNode, Key key, Item item) {
        value first = key.first;
        if (!exists curNode) {
            print("inserting \'``first``\'" );
            // create new node
            value newNode = Node(first, null, null, null, null, false);
            if (nonempty rest = key.rest) {
                // insert Nodes with the rest of the key 
                // into the subtree rooted at newNode 
                newNode.middleChild = insert(newNode.middleChild, rest, item)[0];
            }
            else {
                // newNode received the last element of the key
                // store item in it and mark it as terminal
                newNode.item = item;
                newNode.terminal = true;
            }
            return [newNode, null];
        }
        else {
            value e = curNode.element;
            Item? oldItem;
            switch (first <=> e)
            case (smaller) {
                value [n, i] = insert(curNode.leftChild, key, item);
                curNode.leftChild = n;
                oldItem = i;
            }
            case (larger) {
                value [n, i] = insert(curNode.rightChild, key, item);
                curNode.rightChild = n;
                oldItem = i;
            }
            case (equal) {
                if (nonempty rest = key.rest) {
                    value [n, i] = insert(curNode.middleChild, rest, item);
                    curNode.middleChild = n;
                    oldItem = i;
                }
                else {
                    oldItem = if (curNode.terminal) 
                    then curNode.item 
                    else null;
                    curNode.item = item;
                    curNode.terminal = true; 
                }
            }
            return [curNode, oldItem];
        }
    }
    
    shared actual Item? put(Key key, Item item) {
        value [newRoot, oldItem] = insert(root, key, item);
        root = newRoot;
        return oldItem;
    }
    
    for (key->item in entries) {
        put(key, item);
    }
    
    Node? lookup(Key key, Node? startingNode = root)
            => let (node = search(key, startingNode))
    if (exists node, node.terminal) then node else null; 
    
    Node? search(Key key, Node? curNode) {
        if (!exists curNode) {
            return null; 
        }
        else { 
            switch (key.first <=> curNode.element)
            case (smaller) { 
                return search(key, curNode.leftChild); 
            } 
            case (larger) {
                return search(key, curNode.rightChild); 
            }
            case (equal) {
                if (nonempty rest = key.rest) {
                    return search(rest, curNode.middleChild); 
                }
                else {
                    // the last element of `key` matched the one in `node`
                    return curNode;
                }
            }
        }
    }
    
   
   /*
    //Iterative version of lookup
    Node? lookup(Key key, Node? startingNode = root) {
        variable Node? node = startingNode;
        variable Key k = key;
        print("within lookup");
        print("root:");
        print(root);
        while (exists n = node) {
            print(n.element);
            switch (k.first <=> n.element)
            case (smaller) {
                node = n.leftChild;
            }
            case (larger) {
                node = n.rightChild;
            }
            case (equal) {
                if (nonempty rest = k.rest) {
                    node = n.middleChild;
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
   
    shared actual Item? get(Object key)
            => if (is Key key) 
               then lookup(key)?.item 
               else find(forKey(key.equals))?.item;
   
   
    shared actual Boolean defines(Object key)
            => if (is Key key) 
               then lookup(key) exists 
               else keys.any(key.equals);
   
    void enumerateEntries(Node? node, 
                          MutableList<KeyElement> keyPrefix, 
                          MutableList<Key->Item> queue) {
        if (exists node) {
            // left subtree:
            enumerateEntries(node.leftChild, keyPrefix, queue);
            
            // middle <:
            keyPrefix.add(node.element);
            if (node.terminal) {
                assert (nonempty k = [ for (e in keyPrefix) e ]);
                assert (exists i = node.item);
                queue.add(k->i);
            }
            enumerateEntries(node.middleChild, keyPrefix, queue);
            keyPrefix.deleteLast();
            
            // right subtree:       
            enumerateEntries(node.rightChild, keyPrefix, queue);
        }
    }

    shared actual Iterator<Key->Item> iterator() {
        value queue = ArrayList<Key->Item>();
        enumerateEntries(root, ArrayList<KeyElement>(), queue);
        return queue.iterator();
    }
 
    Node? subtree(Key prefix) 
            => search(prefix, root); 

    shared actual Boolean hasKeyWithPrefix(Object prefix)
            => if (is Key prefix) then (subtree(prefix) exists) else false;

   
    shared actual {Key*} keysWithPrefix(Object prefix)
            => entriesWithPrefix(prefix).map(Entry.key);
   
    //shared actual {<Key->Item>*} entriesWithPrefix(Object prefix)
    //        => oneOrMoreEntriesWithPrefix(prefix) else {};
   
    shared actual {<Key->Item>*} entriesWithPrefix(Object prefix) {
        if (is Key prefix, exists node = subtree(prefix)) {
            value queue = ArrayList<Key->Item>();
            if (node.terminal) {
                assert (is Item i = node.item);
                queue.add(prefix->i);
            }
            enumerateEntries(node.middleChild, 
                             ArrayList<KeyElement> { elements = prefix; }, 
                             queue);
            return queue;
        }
        else {
            return {};
        }
    }
   
    shared actual {Key+}? oneOrMoreKeysWithPrefix(Object prefix)
            => let (entryStream = oneOrMoreEntriesWithPrefix(prefix))
               if (exists entryStream) 
               then entryStream.map(Entry.key) 
               else null;
   
   
    shared actual {<Key->Item>+}? oneOrMoreEntriesWithPrefix(Object prefix) {
        if (is Key prefix, exists node = subtree(prefix)) {
            value queue = ArrayList<Key->Item>();
            if (node.terminal) {
                assert (is Item i = node.item);
                queue.add(prefix->i);
            }
            enumerateEntries(node.middleChild, 
                    ArrayList<KeyElement> { elements = prefix; }, 
                    queue);
            assert (is {<Key->Item>+} queue);
            return queue;
        }
        else {
            return null;
        }
    }
    
    Boolean leaf(Node n)
            => !(n.leftChild exists) 
                && !(n.middleChild exists) && !(n.rightChild exists);
    
    Boolean danglingLeaf(Node n)
            => !n.terminal && leaf(n);
    
    [Node?, Item?, Boolean] removeNodes(Node? curNode, Key key) {
        if (!exists curNode) {
            return [curNode, null, false];
        }
        else {
            value e = curNode.element;
            value first = key.first;
            switch (first <=> e)
            case (smaller) {
                value [n, i, keyRemoved] = 
                        removeNodes(curNode.leftChild, key);
                curNode.leftChild = n;
                return [if (danglingLeaf(curNode)) then null else curNode,
                        i, 
                        keyRemoved]; 
            }
            case (larger) {
                value [n, i, keyRemoved] = 
                        removeNodes(curNode.rightChild, key);
                curNode.rightChild = n;
                return [if (danglingLeaf(curNode)) then null else curNode,
                        i, 
                        keyRemoved]; 
            }
            case (equal) {
                if (nonempty rest = key.rest) {
                    value [n, i, keyRemoved] = 
                            removeNodes(curNode.middleChild, rest);
                    curNode.middleChild = n;
                    
                    Node? retNode; // The node to be returned by this method
                    // If `curNode` remains in the tree, `retNode` will be 
                    // `curNode`. Otherwise, `retNode` will be either null
                    // or a node that takes the place of `curNode`.

                    if (!curNode.terminal && !(n exists)) {
                        // prune non-terminal nodes with no middle child 
                        if (exists l = curNode.leftChild, 
                            exists r = curNode.rightChild) {
                            // The node to be pruned has two children subtrees:
                            // join these subtrees together, creating a subtree
                            // that will take the place of the vanishing node.
                            // We have arbitrarily chosen to put the r subtree 
                            // under the l subtree. (The other way around would
                            // also work.)
                            Node descendRightmostBranch(Node n)
                                    => if (exists rc = n.rightChild)
                                       then descendRightmostBranch(rc)
                                       else n;
                            descendRightmostBranch(l).rightChild = r;
                            retNode = l;
                        }
                        else if (!(curNode.leftChild exists)) {
                            // right child will replace `curNode`
                            retNode = curNode.rightChild; // possibly null
                        }
                        else { // (!(curNode.rightChild exists))
                            // left child will replace `curNode`
                            retNode = curNode.leftChild;
                        }
                    }
                    else {
                        // `curNode` remains in the tree
                        retNode = curNode;
                    }
                    return [retNode, i, keyRemoved];
                }
                else {
                    // current node has the last element of the key
                    print(">>> ``curNode.element``");
                    printNode(curNode);
                    // is it a terminal node?
                    if (curNode.terminal) {
                        // yes: 
                        // mark it as non terminal, 
                        // effectively removing  the given `key` from the tree
                        curNode.terminal = false;
                        // retrieve the value no longer 
                        // associated with the given `key` 
                        Item? removedItem = curNode.item;
                        assert(is Item removedItem);
                        if (leaf(curNode)) {
                            // current node is a leaf: remove it
                            return [null, removedItem, true]; 
                        }
                        else {
                            // current node is not a leaf node, 
                            // so it must remain in the tree
                            return [curNode, removedItem, true]; 
                        }
                    }
                    else {
                        // no: 
                        // cannot remove anything
                        // (sanity check: a non terminal node cannot be a leaf node)
                        assert(!leaf(curNode));
                        return [curNode, null, false];
                    }
                }
            }
        }
    }
         
    
    shared actual Item? remove(Key key) {
        value [newRoot, item, keyRemoved] = removeNodes(root, key);
        root = newRoot;
        return if (keyRemoved) then item else null; 
    }
    
    shared actual void clear() => root = null;
    
    shared actual Boolean equals(Object that) 
            => (super of Map<Key,Item>).equals(that);
    
    shared actual Integer hash => (super of Map<Key,Item>).hash;
    
    shared actual TernaryTreeMap<KeyElement, Item> clone() => copy(this);
    
    void printNode(Node n) {
        print("``n.element``, ``n.item else "null item"``, ``n.leftChild else "no left child"``, ``n.middleChild else "no middle child"``, ``n.rightChild else "no right child"``, ``if (n.terminal) then "terminal" else "nonterminal"``");
    }

    void printTree(Node? n) {
        if (exists n) {
            printNode(n);
            printTree(n.leftChild);
            printTree(n.middleChild);
            printTree(n.rightChild);
        }
    }
    
    shared void printNodes() => printTree(root);
       
}