import ceylon.collection {
    MutableMap,
    MutableList,
    ArrayList
}

class TernaryTreeMap<KeyElement, Item>() 
        satisfies PrefixMap<KeyElement, Item> 
                  & MutableMap<[KeyElement+], Item> 
        given KeyElement satisfies Comparable<KeyElement> {
        
    shared actual Integer hash {
        variable value hash = 1;
        return hash;
    }
    shared actual Boolean equals(Object that) {
        if (is TernaryTreeMap<KeyElement, Item> that) {
            return true;
        }
        else {
            return false;
        }
    }
    shared actual MutableMap<Key, Item> clone() => nothing;
    
    
    class Node(shared KeyElement element,
               shared variable Item? item, 
               shared variable Node? leftChild,
               shared variable Node? middleChild,
               shared variable Node? rightChild,
               shared variable Boolean terminal) {
        
    }
    variable Node? root = null;
    
    Node? lookup(Key key) {
        variable Node? node = root;
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
    
    Node? rLookup(Key key, Node? node) {
        if (!exists node) {
            return null; 
        }
        else { 
            switch (key.first <=> node.element)
            case (smaller) { 
                return rLookup(key, node.leftChild); 
            } 
            case (larger) {
                return rLookup(key, node.rightChild); 
            }
            case (equal) {
                if (nonempty rest = key.rest) {
                    return rLookup(rest, node.middleChild); 
                }
                else {
                    // the last element of `key` matched the one in `node`
                    return node;
                    // return if (node.terminal) then node else null;
                }
            }
        }
    }
   
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
            
            // middle subtree:
            keyPrefix.add(node.element);
            if (node.terminal) {
                assert (is Key k = [ for (e in keyPrefix) e ]);
                assert (is Item i = node.item);
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
            => rLookup(prefix, root); 

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
    
    shared actual void clear() {}
    
    [Node, Item?] insertNodes(Node? currentNode, Key key, Item item) {
        value first = key.first;
        if (!exists currentNode) {
            print("inserting \'``first``\'" );
            // create new node
            value newNode = Node(first, null, null, null, null, false);
            if (nonempty rest = key.rest) {
                // insert Nodes with the rest of the key 
                // into the subtree rooted at newNode 
                newNode.middleChild = insertNodes(newNode.middleChild, rest, item)[0];
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
            value e = currentNode.element;
            Item? oldItem;
            switch (first <=> e)
            case (smaller) {
                value [n, i] = insertNodes(currentNode.leftChild, key, item);
                currentNode.leftChild = n;
                oldItem = i;
            }
            case (larger) {
                value [n, i] = insertNodes(currentNode.rightChild, key, item);
                currentNode.rightChild = n;
                oldItem = i;
            }
            case (equal) {
                if (nonempty rest = key.rest) {
                    value [n, i] = insertNodes(currentNode.middleChild, rest, item);
                    currentNode.middleChild = n;
                    oldItem = i;
                }
                else {
                    oldItem = if (currentNode.terminal) 
                              then currentNode.item 
                              else null;
                    currentNode.item = item;
                    currentNode.terminal = true; 
                }
            }
            return [currentNode, oldItem];
        }
    }
    
    shared actual Item? put(Key key, Item item) {
        value [newRoot, oldItem] = insertNodes(root, key, item);
        root = newRoot;
        return oldItem;
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
                    // TODO: prune non-terminal nodes with no middle child 
                    return [if (danglingLeaf(curNode)) then null else curNode,
                            i, 
                            keyRemoved];
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