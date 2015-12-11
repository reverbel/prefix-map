import ceylon.collection {
    MutableMap,
    MutableList,
    ArrayList
}

class MutableBox<Item>(shared variable Item? content) {}

"""A mutable [[PrefixMap]] implemented using a _ternary search tree_ 
   whose keys are sequences of [[Comparable]] elements. Map entries 
   are mantained in lexicographic order of keys, from the smallest
   to the largest key. The lexicographig ordering of keys relies on 
   comparisons of [[KeyElement]]s, performed either by the method 
   `compare` of the interface [[Comparable]] or by a comparator 
   function specified when the map is created.
 
   Ternary search trees are also known as _lexicographic search trees_.
   For a very short, formal and precise definition of such trees, see
   pages 674-676 of Sleator and Tarjan's paper "Self-Adjusting Binary 
   Search Trees", available [here][sleator-tarjan]. The relevant part
   is in section 6, "Two Applications of Splaying", starting at the 
   bottom of page 674 and going up to the first paragraph of page 676. 
   For a longer discussion, see Bentley and Sedgewick's paper "Fast 
   Algorithms for Sorting and Searching Strings", available 
   [here][bentley-sedgewick], or their article "Ternary Search Trees"
   [in Dr. Dobb's][ternary-search-trees].
   
   [sleator-tarjan]: http://www.cs.cmu.edu/~sleator/papers/self-adjusting.pdf 
                     "Self-Adjusting Binary Search Trees"
                     
   [bentley-sedgewick]: https://www.cs.princeton.edu/~rs/strings/paper.ps
                        "Fast Algorithms for Sorting and Searching Strings"
                     
   [ternary-search-trees]: http://www.drdobbs.com/database/ternary-search-trees/184410528
                        "Ternary Search Trees" """
see (`interface PrefixMap`, `interface Map`, `interface MutableMap`,
     `class Entry`, `interface Comparable`)
tagged ("Collections")
by ("Francisco Reverbel")
shared class TernaryTreeMap<KeyElement, Item> 
        satisfies PrefixMap<KeyElement, Item> 
                  & MutableMap<[KeyElement+], Item> 
        given KeyElement satisfies Comparable<KeyElement> {

    "Minimum length (in `Character`s) of an `Element`, in the output 
     generated by [[printNodes]]."
    variable Integer paddedElementSize = 1;
    
    "Minimum length (in `Character`s) of an `Item`, in the output 
     generated by [[printNodes]]."
    variable Integer paddedItemSize = 6;
    
    class Node(shared KeyElement element,
        shared variable Item? item, 
        shared variable Node? left,
        shared variable Node? middle,
        shared variable Node? right,
        shared variable Boolean terminal) {
        
        shared Node deepCopy() {
            value copy = Node {
                element = this.element;
                item = this.item;
                left = null;
                middle = null;
                right = null;
                terminal = this.terminal;
            };
            if (exists l = left) {
                copy.left = l.deepCopy();
            }
            if (exists m = middle) {
                copy.middle = m.deepCopy();
            }
            if (exists r = right) {
                copy.right = r.deepCopy();
            }
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
        
        shared actual String string =>
                "``id``: "
                + "``element.string.padLeading(paddedElementSize)``, "
                + "``item?.string?.padLeading(paddedItemSize) else "<null>"``, " 
                + "``left?.id else "  no left child"``, "
                + "``middle?.id else "no middle child"``, "
                + "``right?.id else " no right child"``"
                + "``if (terminal) then ", T" else "  "``";
    }
    
    "The root node of the tree."
    variable Node? root;
    
    "The initial entries in the map."
    {<Key->Item>*} entries;
    
    "Alternatively, the root node of a tree to clone."
    Node? nodeToClone;
        
    "A comparator function used to sort the entries."
    Comparison compare(KeyElement x, KeyElement y);
        
    "Create a new `TernaryTreeMap` with the given `entries` and the 
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
    
    "Create a new `TernaryTreeMap` with the same entries and 
     comparator function as the given `TernaryTreeMap`."
    shared new copy(TernaryTreeMap<KeyElement,Item> ternaryTreeMap) {
        entries = {};
        nodeToClone = ternaryTreeMap.root;
        compare = ternaryTreeMap.compare;
    }
    
    // initialization of root
    root = if (exists nodeToClone) 
           then nodeToClone.deepCopy() else null;
    
    Node newVerticalPath(Key key, Item item) {
        variable KeyElement e = key.first;
        variable KeyElement[] rest = key.rest;
        value head = Node(e, null, null, null, null, false);
        variable Node node = head; 
        while (nonempty toCopy = rest) {
            e = toCopy.first;
            rest = toCopy.rest;
            value newNode = Node(e, null, null, null, null, false);
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
                n.left = newVerticalPath(suffix, item);
                return null;  
            }
            case (equal) {
                if (nonempty suffix = keySuffix) {
                    "reached the end of a vertical path"
                    assert(!n.middle exists);
                    "any node with no middle child must be terminal"
                    assert(n.terminal);
                    n.middle = newVerticalPath(suffix, item);
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
                n.right = newVerticalPath(suffix, item);
                return null;  
            }
        }
        else {
            root = newVerticalPath(key, item);
            return null;
        }
    }

    // Add initial entries
    for (key->item in entries) {
        put(key, item);
    }
    
    // End of initializer section
    
    Node? lookup(Key key, Node? startingNode = root)
            => let (node = search(key, startingNode))
               if (exists node, node.terminal) then node else null; 
    
    Node? search(Key key, Node? node) {
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
   
    shared actual Item? get(Object key)
            => if (is Key key) 
               then lookup(key)?.item 
               else find(forKey(key.equals))?.item;
   
   
    shared actual Boolean defines(Object key)
            => if (is Key key) 
               then lookup(key) exists 
               else keys.any(key.equals);
   
    // Puts in the given `queue` all the entries with the given 
    // `keyPrefix` in the subtree rooted at the given `node`. 
    // The entries are enqueued in lexicographic order of keys, 
    // from the smallest to the largest key.  
    void enumerateEntries(Node? node, 
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
            enumerateEntries(node.middle, 
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
            enumerateEntries(node.middle, 
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
            => !(n.left exists) && !(n.middle exists) && !(n.right exists);
    
    Boolean danglingLeaf(Node n)
            => !n.terminal && leaf(n);
    
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
                return if (danglingLeaf(node)) then null else node;
            }
            case (larger) {
                node.right = removeNodes(node.right, itemRemoved, key);
                return if (danglingLeaf(node)) then null else node;
            }
            case (equal) {
                if (nonempty rest = key.rest) {
                    node.middle = removeNodes(node.middle, itemRemoved, rest);  
                    
                    Node? retNode; // The node to be returned by this method
                    // If `curNode` remains in the tree, `retNode` will be 
                    // `curNode`. Otherwise, `retNode` will be either null
                    // or a node that takes the place of `curNode`.
                    
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
                            descendRightmostBranch(l).right = r;
                            retNode = l;
                        }
                        else if (!(node.left exists)) {
                            // right child will replace `curNode`
                            retNode = node.right; // possibly null
                        }
                        else { // (!(curNode.right exists))
                            // left child will replace `curNode`
                            retNode = node.left;
                        }
                    }
                    else {
                        // `curNode` remains in the tree
                        retNode = node;
                    }
                    return retNode;
                }
                else {
                    // current node has the last element of the key
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
                            // current node is a leaf: remove it
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
                        "sanity check: a non terminal node cannot be a leaf node"
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
        return itemRemoved.content; 
    }
    
    shared actual void clear() 
            => root = null;
    
    shared actual Integer size 
            => root?.size else 0;
    
    shared actual Boolean equals(Object that) 
            => (super of Map<Key,Item>).equals(that);
    
    shared actual Integer hash 
            => (super of Map<Key,Item>).hash;
    
    shared actual TernaryTreeMap<KeyElement, Item> clone() 
            => copy(this);
    
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
        Integer paddedElementSize = 1, 
        "Minimum length (in `Character`s) of an `Item`, in the output
         generated by [[printNodes]]."
        Integer paddedItemSize = 6) {
        this.paddedElementSize = paddedElementSize;
        this.paddedItemSize = paddedItemSize;
        printSubtree(root);     
    }

}
