import ceylon.collection {
    MutableMap,
    MutableList,
    ArrayList
}

"Minimum length (in `Character`s) of an `Element`, in the output 
 generated by `someTernaryTree.printNodes()`."
variable Integer paddedElementSize = 1;

"Minimum length (in `Character`s) of an `Item`, in the output 
 generated by `someTernaryTree.printNodes()`."
variable Integer paddedItemSize = 6;


shared class TreeNode<KeyElement, Item>(
    shared KeyElement element)
        given KeyElement satisfies Object {
    
    shared variable Item? item = null; 
    shared variable TreeNode<KeyElement, Item>? parent = null;
    shared variable TreeNode<KeyElement, Item>? left = null;
    shared variable TreeNode<KeyElement, Item>? middle = null;
    shared variable TreeNode<KeyElement, Item>? right = null;
    shared variable Boolean terminal = false;
    
    shared TreeNode<KeyElement, Item> deepCopy() {
        value copy = TreeNode<KeyElement, Item>(this.element);
        copy.item = this.item;
        if (exists l = left) {
            value leftCopy = l.deepCopy();
            leftCopy.parent = copy;
            copy.left = leftCopy;
        }
        if (exists m = middle) {
            value middleCopy = m.deepCopy();
            middleCopy.parent = copy;
            copy.middle = middleCopy;
        }
        if (exists r = right) {
            value rightCopy = r.deepCopy();
            rightCopy.parent = copy;
            copy.right = rightCopy;
        }
        copy.terminal = this.terminal;
        return copy;
    }
    
    shared Integer size {
        variable Integer size = if (terminal) then 1 else 0;
        if (exists l = left) {
            size += l.size;
        }
        if (exists m = middle) {
            size += m.size;
        }
        if (exists r = right) {
            size += r.size;
        }
        return size;
    }
    
    String id =>
            "Node@``hash.string.padLeading(10, '_')``";
    
    shared actual String string {
        value sBuilder = StringBuilder();
        sBuilder.append(id)
                .append(": ")
                .append(element.string.padLeading(paddedElementSize))
                .append(", ")
                .append(item?.string?.padLeading(paddedItemSize) else "<null>")
                .append(", ")
                .append(left?.id else "  no left child")
                .append(", ")
                .append(middle?.id else "no middle child")
                .append(", ")
                .append(right?.id else " no right child");
        if (terminal) {
            sBuilder.append(", T");
        }
        return sBuilder.string;
    }
}

shared abstract class AbstractTernaryTree<KeyElement, Item>()
        satisfies PrefixMap<KeyElement, Item> 
                  & MutableMap<[KeyElement+], Item> 
        given KeyElement satisfies Comparable<KeyElement> {
    
    shared class Node(KeyElement element) 
            => TreeNode<KeyElement, Item>(element);

    "The root node of the tree."
    shared formal variable Node? root;

    "A comparator function used to sort the entries."
    shared formal Comparison(KeyElement, KeyElement) compare;
    
    //shared actual formal Item? put(Key key, Item item);

    //shared actual formal Item? remove(Key key);
    
    //shared actual formal AbstractTernaryTree<KeyElement, Item> clone();
    
    shared formal Node? search(Key key, Node? node);
    
    Node? lookup(Key key, Node? startingNode = root)
            => let (node = search(key, startingNode))
               if (exists node, node.terminal) then node else null; 
    
    shared actual Item? get(Object key)
            => if (is Key key) 
               then lookup(key)?.item 
               else find(forKey(key.equals))?.item;
    
    shared actual Boolean defines(Object key)
            => if (is Key key) 
               then lookup(key) exists 
               else keys.any(key.equals);

    Node? firstTerminalNode(MutableList<KeyElement> key) {
        if (exists node = root) {
            variable Node current = node;
            while (true) {
                if (exists left = current.left) {
                    current = left;
                }
                else if (!current.terminal) {
                    assert (exists middle = current.middle);
                    key.add(current.element);
                    current = middle;
                }
                else {
                    key.add(current.element);
                    return current;
                }
            }
        }
        else {
            return null;
        }
    }
    
    Node? lastTerminalNode(MutableList<KeyElement> key) {
        if (exists node = root) {
            variable Node current = node;
            while (true) {
                if (exists right = current.right) {
                    current = right;
                }
                else if (exists middle = current.middle) {
                    key.add(current.element);
                    current = middle;
                }
                else {
                    assert (current.terminal);
                    key.add(current.element);
                    return current;
                }
            }
        }
        else {
            return null;
        }
    }
    
    Key->Item entry(MutableList<KeyElement> keyPrefix, Node terminalNode) {
        assert (terminalNode.terminal);
        assert (is Item item = terminalNode.item);
        value key =
                [ for (e in keyPrefix) e ].withTrailing(terminalNode.element);
        return key->item;
    }

     class EntryIterator(keyPrefix, currentNode)
            satisfies Iterator<Key->Item> {
        MutableList<KeyElement> keyPrefix;
        variable Node? currentNode;
        variable Node? previousNode = null;
        shared actual <Key->Item>|Finished next() {
            if (exists current = currentNode) {
                value theEntry = entry(keyPrefix, current);
                // Will return `theEntry`,
                // but must update the iterator state before returning
                variable Node node = current;  
                variable Boolean done = false;
                // Leaves the loop below with `node` containing the next
                // terminal `Node` to visit or with `currentNode` set to null 
                while (!done) {
                    print(">>> ``node``");
                    if (exists previous = previousNode) {
                        previousNode = node;
                        if (exists left = node.left, previous === left) {
                            // Backtracking from left subtree
                            if (exists middle = node.middle) {
                                // Proceed to middle subtree
                                keyPrefix.add(node.element);
                                print(">>>>> ``keyPrefix``");
                                node = middle;
                                if (node.terminal) {
                                    done = true;
                                }
                            }
                            else if (exists right = node.right) {
                                // Proceed to right subtree
                                node = right;
                                if (node.terminal) {
                                    done = true;
                                }
                            }
                            else if (exists parent = node.parent) {
                                // Backtrack to parent node
                                node = parent;
                            }
                            else {
                                // End of stream
                                currentNode = null;
                                done = true;
                            }
                        }
                        else if (exists middle = node.middle,
                                 previous === middle) {
                            // Backtracking from middle subtree
                            keyPrefix.deleteLast();
                            print(">>>>> ``keyPrefix``");
                            if (exists right = node.right) {
                                // Proceed to right subtree
                                node = right;
                                if (node.terminal) {
                                    done = true;
                                }
                            }
                            else if (exists parent = node.parent){
                                // Backtrack to parent node
                                node = parent;
                            }
                            else {
                                // End of stream
                                currentNode = null;
                                done = true;
                            }
                        }
                        else if (exists right = node.right,
                                 previous === right) {
                            // Backtracking from right subtree 
                            if (exists parent = node.parent){
                                // Backtrack to parent node
                                node = parent;
                            }
                            else {
                                // End of stream
                                currentNode = null;
                                done = true;
                            }
                        }
                        else if (exists parent = node.parent,
                                 previous === parent) {
                            // Coming from the parent node
                            if (exists left = node.left) {
                                // Proceed to left subtree
                                node = left;
                                if (node.terminal) {
                                    done = true;
                                }
                            }
                            else if (exists middle = node.middle) {
                                // Proceed to middle subtree
                                keyPrefix.add(node.element);
                                print(">>>>> ``keyPrefix``");
                                node = middle;
                                if (node.terminal) {
                                    done = true;
                                }
                            }
                            else if (exists right = node.right) {
                                // Proceed to right subtree
                                node = right;
                                if (node.terminal) {
                                    done = true;
                                }
                            }
                            else {
                                // Backtrack to the parent node
                                node = parent;
                            }
                        }
                        else {
                            // Reaching this point would mean that
                            // the previous node exists, but it is 
                            // neither the parent node nor one of 
                            // the children nodes.
                            "bug: this code should never be reached"
                            assert(false); 
                        }
                    }
                    else {
                        // Got here because there was no previous node.
                        // This must be the very first call to `next()`.
                        // Well, henceforth there will be a previous node.  
                        previousNode = node;
                        if (exists middle = node.middle) {
                            // Proceed to middle subtree
                            keyPrefix.add(node.element);
                            print(">>>>> ``keyPrefix``");
                            node = middle;
                            if (node.terminal) {
                                done = true;
                            }
                        }
                        else if (exists right = node.right) {
                            // Proceed to right subtree
                            node = right;
                            if (node.terminal) {
                                done = true;
                            }
                        }
                        else if (exists parent = node.parent) {
                            // Backtrack to parent
                            node = parent;
                            if (node.terminal) {
                                done = true;
                            }
                        }
                        else {
                            // End of stream
                            currentNode = null;    
                            done = true;
                        }
                    }
                }
                if (currentNode exists) {
                    currentNode = node;
                    "at this point `node` must be terminal"
                    assert (node.terminal);
                }
                return theEntry;
            }
            else {
                return finished;
            }
            
        }
    }

    shared actual <Key->Item>? first {
        value key = ArrayList<KeyElement>();
        if (exists node = firstTerminalNode(key)) {
            assert (nonempty k = [ for (e in key) e ]);
            assert (is Item i = node.item);
            return k->i;
        }
        else {
            return null;
        }
    }
    
    shared actual <Key->Item>? last {
        value key = ArrayList<KeyElement>();
        if (exists node = lastTerminalNode(key)) {
            assert (nonempty k = [ for (e in key) e ]);
            assert (is Item i = node.item);
            return k->i;
        }
        else {
            return null;
        }
    }
    
    shared actual Iterator<Key->Item> iterator() {
        value key = ArrayList<KeyElement>();
        value node = firstTerminalNode(key);
        if (node exists) {
            key.deleteLast();
        }
        return EntryIterator(key, node);
    }
    
    // Puts in the given `queue` all the entries with the given 
    // `keyPrefix` in the subtree rooted at the given `node`. 
    // The entries are enqueued in lexicographic order of keys, 
    // from the smallest to the largest key.  
    shared void enumerateEntries(Node? node, 
                                 MutableList<KeyElement> keyPrefix, 
                                 MutableList<Key->Item> queue) {
        if (exists node) {
            // left subtree:
            enumerateEntries(node.left, keyPrefix, queue);
            
            // middle subtree:
            keyPrefix.add(node.element);
            if (node.terminal) {
                assert (nonempty k = [ for (e in keyPrefix) e ]);
                assert (exists i = node.item);
                queue.add(k->i);
            }
            enumerateEntries(node.middle, keyPrefix, queue);
            keyPrefix.deleteLast();
            
            // right subtree:       
            enumerateEntries(node.right, keyPrefix, queue);
        }
    }
    
    shared Iterator<Key->Item> eagerIterator() {
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
    
    shared actual {<Key->Item>*} entriesWithPrefix(Object prefix) {
        if (is Key prefix, exists node = subtree(prefix)) {
            value queue = ArrayList<Key->Item>();
            if (node.terminal) {
                assert (is Item i = node.item);
                queue.add(prefix->i);
            }
            enumerateEntries(node.middle, 
                ArrayList<KeyElement> { elements = prefix; }, 
                queue);
            return queue;
        }
        else {
            return {};
        }
    }
    
    shared actual void clear() 
            => root = null;
    
    shared actual Integer size 
            => root?.size else 0;
    
    shared actual Boolean equals(Object that) 
            => (super of Map<Key,Item>).equals(that);
    
    shared actual Integer hash 
            => (super of Map<Key,Item>).hash;
    
    // begin TODO section
        
    shared actual {<Key->Item>*} ascendingEntries(Key from, Key to) => nothing;
    
    shared actual {<Key->Item>*} descendingEntries(Key from, Key to) => nothing;
    
    shared actual {<Key->Item>*} higherEntries(Key key) => nothing;
    
    shared actual {<Key->Item>*} lowerEntries(Key key) => nothing;
    
    shared actual PrefixMap<KeyElement,Item> measure(Key from, Integer length) => nothing;
    
    shared actual PrefixMap<KeyElement,Item> span(Key from, Key to) => nothing;
    
    shared actual PrefixMap<KeyElement,Item> spanFrom(Key from) => nothing;
    
    shared actual PrefixMap<KeyElement,Item> spanTo(Key to) => nothing;
    
    // end TODO section
    
    void printSubtree(Node? n) {
        if (exists n) {
            print(n);
            printSubtree(n.left);
            printSubtree(n.middle);
            printSubtree(n.right);
        }
    }
    
    "Prints a series of lines to the standart output of the virtual machine
     process, with one line per node of this tree. Each line has the format
     ~~~Text
     Node@<nnnnnnnn>: <element>, <item>, <left child>, <middle child>, <right child>, T
     ~~~
     or the format
     ~~~Text
     Node@<nnnnnnnn>: <element>, <item>, <left child>, <middle child>, <right child>
     ~~~
         
     - The field `<nnnnnnnn>` is the `hash` of the node, left padded 
       with `'_'` characters to a minimum lenght of 10 characteres. 
     - The field `<element>` is the string representation of the 
       `KeyElement` in the node. 
     - The field `<item>` is the string representation of the `Item`
       in the node, or `<null>` if there is no `Item` in the node.
     - The fields `<left child>`, `<middle child>,` and `<right child>`
       identify the corresponding child nodes. Each of these fields has
       the format `Node@<nnnnnnnn>` if the corresponding child node 
       exists, otherwise it contains the text `no left child` (in the 
       case of a missing left child), or the text `no middle child` (in 
       the case of a missing middle child), or the text `no right child`
       (in the case of a missing right child).
     - Lines with the first format (with an ending \`'T'\`) represent 
       terminal nodes, lines with the second format represent nonterminal 
       nodes. 
        
     The example below shows a section of the output produced by a call to
     `printNodes` on a `TernaryTreeMap<Character, Integer>`.   
     ~~~Text
     Node@_596706728: b, <null>, Node@2106900153, Node@1070501849, Node@1298146757  
     Node@2106900153: a, <null>,   no left child, Node@1443055846,  no right child  
     Node@1443055846: t,      2, Node@_502838712, no middle child,  no right child, T
     Node@_502838712: s,      2,   no left child, no middle child,  no right child, T     
     ~~~
     
     This method is intended mainly for debugging purposes."
    shared void printNodes(
        "Minimum length (in `Character`s) of an `Element`, in the output
         generated by [[printNodes]]."
        Integer paddedElementLength = 1, 
        "Minimum length (in `Character`s) of an `Item`, in the output
         generated by [[printNodes]]."
        Integer paddedItemLength = 6) {
        paddedElementSize = paddedElementLength;
        paddedItemSize = paddedItemLength;
        printSubtree(root);     
    }
    
}