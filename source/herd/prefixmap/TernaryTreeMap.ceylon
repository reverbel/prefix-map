import ceylon.collection {
    MutableMap,
    MutableList,
    ArrayList
}

"""A mutable [[PrefixMap]] backed by a _ternary search tree_ whose 
   keys are sequences of [[Comparable]] elements. Map entries are 
   mantained in lexicographic order of keys, from the smallest to 
   the largest key. The lexicographic ordering of keys relies on 
   [[KeyElement]] comparisons performed by a formal `compare`
   function. The [[TernaryTreeMap]] implementations in this package 
   provide a default `compare` function based on the "natural" 
   comparison of key elements. (The default function merely delegates
   its task to the [[KeyElement]]s themselves, which are [[Comparable]]).
   Moreover, these [[TernaryTreeMap]] implementations also accept
   client-defined comparison functions, for example to specify a 
   character ordering that groups together uppercase and lowercase 
   letters.
   
   [[TernaryTreeMap]] is an abstract supertype for the concrete ternary
   tree map implementations [[TernarySearchTreeMap]] and
   [[TernarySplayTreeMap]]. In order to satisfy the [[TernaryTreeMap]]
   interface, a concrete class must provide actual implementations for 
   the formal attributes [[rootNode]] and [[compare]], as well as for the 
   formal methods [[search]], [[put]], [[remove]], [[createAnotherMap]], 
   [[clone]], [[equals]], and [[hash]]."""
see (`interface PrefixMap`,
     `interface Map`, `class Entry`, `interface Comparable`,
     `class TernarySearchTreeMap`, `class TernarySplayTreeMap`)
tagged ("Collections")
by ("Francisco Reverbel")
shared interface TernaryTreeMap<KeyElement, Item>
        satisfies PrefixMap<KeyElement, Item> 
                  & MutableMap<[KeyElement+], Item> 
                  & Ranged<[KeyElement+],
                           [KeyElement+]->Item,
                           TernaryTreeMap<KeyElement,Item>>
        given KeyElement satisfies Comparable<KeyElement> {
    
    "A node of this tree. `Node` is a convenient alias for
     `TernaryTreeNode<KeyElement, Item>`."
    see (`class TernaryTreeNode`)
    class Node(KeyElement element) 
            => TernaryTreeNode<KeyElement, Item>(element);
    
    "An object that is the root node of the tree, or `null` in the case 
     of an empty tree. _This attribute is not intended for use by client
     code._ Its purpose is merely to serve as a \"hook\" through which
     methods actually defined by interface [[TernaryTreeMap]] have access
     to the root object provided by a concrete [[TernaryTreeMap]]
     implementation.
     
     In order to check if this map is empty, client code should use the
     attribute [[empty]] instead."
    shared formal Object? rootNode;
    
    "A comparator function used to sort the key elements."
    shared formal Comparison(KeyElement, KeyElement) compare;
    
    "Factory method that creates another `TernaryTreeMap` with the given
     `entries` and the comparator function specified by the parameter 
     `compare`." 
    shared formal TernaryTreeMap<KeyElement, Item> createAnotherMap(
        "The initial entries in the new map. If `entries` is absent,
         an empty map will be created. "
        {<Key->Item>*} entries = {},
        "A function used to compare key elements.
         If `compare` is absent, the comparator method of interface
         [[Comparable]] will be used to compare `KeyElement`s."
        Comparison(KeyElement, KeyElement) compare = 
                (KeyElement x, KeyElement y) => x.compare(y)        
    );
    
    "Determines if this map is empty, that is, if it has no entries."
    shared actual default Boolean empty 
            => rootNode is Null;
    
    "The root node of the tree, or `null` in the case of an empty tree."
    Node? root
            => if (is Node r = rootNode) then r else null;
    
    shared actual formal TernaryTreeMap <KeyElement, Item> clone();
    
    //shared actual formal Item? put(Key key, Item item);

    //shared actual formal Item? remove(Key key);
    
    "Searches for a `key` in this ternary tree. _This method is not intended
     for use by client code._ Its purpose is merely to serve as a \"hook\" 
     through which methods actually defined by interface [[TernaryTreeMap]]
     have access to search functionality provided by a concrete
     [[TernaryTreeMap]] implementation. 
     
     A call to [[search]] returns either the last node of a middle path 
     with the sequence of elements of the given `key`, or `null` if there 
     is no such middle path. A node returned by `search` is not necessarily
     terminal. If `tree.search(key)` returns a terminal node, then `key` is
     actually present in the tree, and the returned node contains the item
     associated with `key`. If `tree.search(key)` returns a non-terminal
     node, `key` appears only as a prefix of some key in the tree, and there
     is no item associated with `key`.

     In order to search for a key in this map, client code should use the
     method [[get]] instead."
    shared formal Object? search(Key key);
    
    Node? lookup(Key key)
            => let (node = search(key))
               if (is Node node, node.terminal) then node else null; 
    
    shared actual Item? get(Object key)
            => if (is Key key) 
               then lookup(key)?.item 
               else find(forKey(key.equals))?.item;
    
    shared actual Boolean defines(Object key)
            => if (is Key key) 
               then lookup(key) exists 
               else keys.any(key.equals);

    "Returns the terminal node that corresponds to the first entry (in
     lexicographic order) within the subtree rooted at the given `root`,
     or `null` if that subtree is empty (i.e., if `root` does not exist).
     Whenever this method returns a terminal node, it also adds to the
     list `key` the sequence of key elements that forms the key in the
     corresponding entry. Whenever this method returns `null`, it leaves 
     unchanged list `key`." 
    Node? firstTerminalNode(MutableList<KeyElement> key, Node? root) {
        if (exists node = root) {
            variable Node current = node;
            while (true) {
                if (exists left = current.left) {
                    current = left;
                }
                else { 
                    key.add(current.element);
                    if (!current.terminal) {
                        assert (exists middle = current.middle);
                        current = middle;
                    }
                    else {
                        return current;
                    }
                }
            }
        }
        else {
            return null;
        }
    }
    
    "Returns the terminal node that corresponds to the last entry (in
     lexicographic order) within the subtree rooted at the given `root`,
     or `null` if that subtree is empty (i.e., if `root` does not exist).
     Whenever this method returns a terminal node, it also adds to the
     list `key` the sequence of key elements that forms the key in the
     corresponding entry. Whenever this method returns `null`, it leaves
     unchanged the list `key`."  
    Node? lastTerminalNode(MutableList<KeyElement> key, Node? root) {
        if (exists node = root) {
            variable Node current = node;
            while (true) {
                if (exists right = current.right) {
                    current = right;
                }
                else {
                    key.add(current.element);
                    if (exists middle = current.middle) {
                        current = middle;
                    }
                    else {
                        assert (current.terminal);
                        return current;
                    }
                }
            }
        }
        else {
            return null;
        }
    }

    "Receives in `keyPrefix` a (possibly empty) list of key elements with
     all but the last element of a key and in `terminalNode` the terminal
     node that contains both the last element of that key and the 
     corresponding item. Returns an `Entry` with the key and the item."
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
                // Will return `theEntry`,
                // but must update the iterator state before returning
                value theEntry = entry(keyPrefix, current);
                variable Node node = current;  
                variable Boolean done = false;
                void proceedTo(Node n) {
                    node = n;
                    if (node.terminal && !node.left exists) {
                        done = true;
                    }
                }
                void backtrackTo(Node parent) {
                    if (parent.terminal, exists leftSibling = parent.left, 
                                         leftSibling === node) {
                        done = true;
                    }
                    node = parent;
                }
                void endOfStream() {
                    currentNode = null;
                    done = true;
                }
                // Leaves the loop below with `node` containing the next
                // terminal `Node` to visit or with `currentNode` set to `null` 
                while (!done) {
                    if (exists previous = previousNode) {
                        previousNode = node;
                        if (exists left = node.left, previous === left) {
                            // Backtracking from left subtree --------------
                            if (exists middle = node.middle) {
                                keyPrefix.add(node.element);
                                proceedTo(middle);
                            }
                            else if (exists right = node.right) {
                                proceedTo(right);
                            }
                            else if (exists parent = node.parent) {
                                backtrackTo(parent);
                            }
                            else {
                                endOfStream();
                            }
                        }
                        else if (exists middle = node.middle,
                                 previous === middle) {
                            // Backtracking from middle subtree ------------
                            keyPrefix.deleteLast();
                            if (exists right = node.right) {
                                proceedTo(right);
                            }
                            else if (exists parent = node.parent) {
                                backtrackTo(parent);
                            }
                            else {
                                endOfStream();
                            }
                        }
                        else if (exists right = node.right,
                                 previous === right) {
                            // Backtracking from right subtree -------------
                            if (exists parent = node.parent) {
                                backtrackTo(parent);
                            }
                            else {
                                endOfStream();
                            }
                        }
                        else if (exists parent = node.parent,
                                 previous === parent) {
                            // Coming from the parent node -----------------
                            if (exists left = node.left) {
                                proceedTo(left);
                            }
                            else if (exists middle = node.middle) {
                                keyPrefix.add(node.element);
                                proceedTo(middle);
                            }
                            else if (exists right = node.right) {
                                proceedTo(right);
                            }
                            else {
                                backtrackTo(parent);
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
                        // Got here because there was no previous node,
                        // so this must be the very first call to `next()`.
                        previousNode = node;
                        if (exists middle = node.middle) {
                            keyPrefix.add(node.element);
                            proceedTo(middle);
                        }
                        else if (exists right = node.right) {
                            proceedTo(right);
                        }
                        else if (exists parent = node.parent) {
                            backtrackTo(parent);
                        }
                        else {
                            endOfStream();
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

    class ReverseEntryIterator(keyPrefix, currentNode)
            satisfies Iterator<Key->Item> {
        MutableList<KeyElement> keyPrefix;
        variable Node? currentNode;
        variable Node? previousNode = null;
        shared actual <Key->Item>|Finished next() {
            if (exists current = currentNode) {
                // Will return `theEntry`,
                // but must update the iterator state before returning
                value theEntry = entry(keyPrefix, current);
                variable Node node = current;  
                variable Boolean done = false;
                void proceedTo(Node n) {
                    node = n;
                    if (node.terminal && !node.right exists 
                                      && !node.middle exists) {
                        done = true;
                    }
                }
                void backtrackTo(Node parent) {
                    if (exists middleSibling = parent.middle, 
                               middleSibling === node) {
                        keyPrefix.deleteLast();
                        if (parent.terminal) {
                            done = true;
                        }
                    }
                    else if (parent.terminal,
                             !parent.middle exists, 
                             exists rightSibling = parent.right,
                             rightSibling === node) {
                        done= true;
                    }
                    node = parent;
                }
                void endOfStream() {
                    currentNode = null;
                    done = true;
                }
                // Leaves the loop below with `node` containing the next
                // terminal `Node` to visit or with `currentNode` set to `null` 
                while (!done) {
                    if (exists previous = previousNode) {
                        previousNode = node;
                        if (exists right = node.right, previous === right) {
                            // Backtracking from right subtree -------------
                            if (exists middle = node.middle) {
                                keyPrefix.add(node.element);
                                proceedTo(middle);
                            }
                            else if (exists left = node.left) {
                                proceedTo(left);
                            }
                            else if (exists parent = node.parent) {
                                backtrackTo(parent);
                            }
                            else {
                                endOfStream();
                            }
                        }
                        else if (exists middle = node.middle,
                                 previous === middle) {
                            // Backtracking from middle subtree ------------
                            if (exists left = node.left) {
                                proceedTo(left);
                            }
                            else if (exists parent = node.parent) {
                                backtrackTo(parent);
                            }
                            else {
                                endOfStream();
                            }
                        }
                        else if (exists left = node.left,
                                 previous === left) {
                            // Backtracking from left subtree --------------
                            if (exists parent = node.parent) {
                                backtrackTo(parent);
                            }
                            else {
                                endOfStream();
                            }
                        }
                        else if (exists parent = node.parent,
                                 previous === parent) {
                            // Coming from the parent node -----------------
                            if (exists right = node.right) {
                                proceedTo(right);
                            }
                            else if (exists middle = node.middle) {
                                keyPrefix.add(node.element);
                                proceedTo(middle);
                            }
                            else if (exists left = node.left) {
                                proceedTo(left);
                            }
                            else {
                                backtrackTo(parent);
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
                        // Got here because there was no previous node,
                        // so this must be the very first call to `next()`.
                        previousNode = node;
                        if (exists middle = node.middle) {
                            keyPrefix.add(node.element);
                            proceedTo(middle);
                        }
                        else if (exists left = node.left) {
                            proceedTo(left);
                        }
                        else if (exists parent = node.parent) {
                            backtrackTo(parent);
                        }
                        else {
                            endOfStream();
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
        if (exists node = firstTerminalNode(key, root)) {
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
        if (exists node = lastTerminalNode(key, root)) {
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
        value node = firstTerminalNode(key, root);
        if (node exists) {
            key.deleteLast();
        }
        return EntryIterator(key, node);
    }
    
    "Puts in the given `queue` all the entries with the given 
     `keyPrefix` in the subtree rooted at the given `node`. 
     The entries are enqueued in lexicographic order of keys, 
     from the smallest to the largest key."  
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

    "An eager iterator for the entries in this ternary tree."
    shared Iterator<Key->Item> eagerIterator() {
        value queue = ArrayList<Key->Item>();
        enumerateEntries(root, ArrayList<KeyElement>(), queue);
        return queue.iterator();
    }
    
    shared actual Boolean hasKeyWithPrefix(Object prefix)
            => if (is Key prefix) then (search(prefix) exists) else false;
    
    
    shared actual {Key*} keysWithPrefix(Object prefix)
            => entriesWithPrefix(prefix).map(Entry.key);
    
    shared actual {<Key->Item>*} entriesWithPrefix(Object prefix) {
        if (is Key prefix, is Node node = search(prefix)) {
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
    
    shared actual Integer size 
            => root?.size else 0;
    
    "Returns the node with the largest element less than or equal to `e`
     within the _binary_ subtree rooted at the given `node`, or `null` if 
     all the nodes of that subtree have elements greater than `e`."
    Node? bstFloor(KeyElement e, Node? node = root) {
        variable Node? currentNode = node;
        variable Node? bestSoFar = null;
        while (exists n = currentNode) {
            switch (compare(n.element, e))
            case (smaller) {
                bestSoFar = n;
                currentNode = n.right;
            }        
            case (equal) {
                return n;
            }        
            case (larger) {
                currentNode = n.left;
            }        
        }
        return bestSoFar;
    }
    
    "Returns the node with the largest element less than `e` within the
     _binary_ subtree rooted at the given `node`, or `null` if all nodes
     of that subtree have elements greater than or equal to `e`."  
    Node? bstStrictFloor(KeyElement e, Node? node = root) {
        variable Node? currentNode = node;
        variable Node? bestSoFar = null;
        while (exists n = currentNode) {
            if ((compare(n.element, e)) == smaller) {
                bestSoFar = n;
                currentNode = n.right;
            }
            else {        
                currentNode = n.left;
            }        
        }
        return bestSoFar;
    }
    
    "Returns the node with the smallest element greater than or equal
     to  `e` within the _binary_ subtree rooted at the given `node`, or
     `null` if all the nodes of that subtree have elements less than `e`."  
    Node? bstCeiling(KeyElement e, Node? node = root) {
        variable Node? currentNode = node;
        variable Node? bestSoFar = null;
        while (exists n = currentNode) {
            switch (compare(n.element, e))
            case (smaller) {
                currentNode = n.right;
            }        
            case (equal) {
                return n;
            }        
            case (larger) {
                bestSoFar = n;
                currentNode = n.left;
            }        
        }
        return bestSoFar;
    }
    
    "Returns the node with the smallest element greater than `e` within
     the _binary_ subtree rooted at the given `node`, or `null` if all the
     nodes of that subtree have elements less than or equal to `e`."
    Node? bstStrictCeiling(KeyElement e, Node? node = root) {
        variable Node? currentNode = node;
        variable Node? bestSoFar = null;
        while (exists n = currentNode) {
            if ((compare(n.element, e)) == larger) {
                bestSoFar = n;
                currentNode = n.left;
            }
            else {        
                currentNode = n.right;
            }        
        }
        return bestSoFar;
    }
    
    "Returns the terminal node with the largest key less than or equal to
     `key` within the ternary subtree rooted at the given `node`, or `null`
     if all the terminal nodes of that subtree have keys greater than `key`."  
    Node? floor(Key key, MutableList<KeyElement> keyAccumulator, Node? node) {
        if (exists cur = bstFloor(key.first, node)) {
            switch (compare (cur.element, key.first))
            case (smaller) {
                keyAccumulator.add(cur.element);
                return if (cur.terminal) then cur
                       else lastTerminalNode(keyAccumulator, cur.middle);
            }        
            case (equal) {
                if (nonempty rest = key.rest) {
                    keyAccumulator.add(cur.element);
                    if (exists middle = cur.middle) {
                        value t = floor(rest, keyAccumulator, middle);
                        if (t exists) {
                            return t;
                        }
                        else if (cur.terminal) {
                             return cur;
                        }
                        else {
                            // the element in node `cur` is too large,
                            // try an alternative node with a smaller element   
                            keyAccumulator.deleteLast();
                            if (exists alt = bstStrictFloor(key.first, node)) {
                                if (alt === cur) {
                                    return null;
                                }
                                else {
                                    keyAccumulator.add(alt.element);
                                    return if (alt.terminal) then alt 
                                           else lastTerminalNode(keyAccumulator, 
                                                                  alt);
                                }
                            }
                            else {
                                return null;
                            }
                        }
                    }
                    else {
                        assert(cur.terminal);
                        return cur;
                    }
                }
                else { // key.rest is empty
                    if (cur.terminal) {
                        keyAccumulator.add(cur.element);
                        return cur;
                    }
                    else {
                        // `key` is a proper prefix of the key in this
                        // tree path, so all keys further down along any
                        // continuation of this path are greater (longer) 
                        // than `key`. Try an alternative path.
                        if (exists alt = bstStrictFloor(key.first, node)) {
                            if (alt === cur) {
                                return null;
                            }
                            else {
                                keyAccumulator.add(alt.element);
                                if (alt.terminal) { 
                                    return alt; 
                                }
                                else {
                                    return lastTerminalNode(keyAccumulator,
                                                            alt);
                                }
                            }
                        }
                        else {
                            return null;
                        }
                    }
                }
            }        
            case (larger) {
                "cannot happen"
                assert(false);
            }        
        }
        else {
            return null;
        }
    }

    "Returns the terminal node with the smallest key greater than or equal to
     `key` within the ternary subtree rooted at the given `node`, or `null`
     if all the terminal nodes of that subtree have keys less than `key`."  
    Node? ceiling(Key key, 
                  MutableList<KeyElement> keyAccumulator, Node? node) {
        if (exists cur = bstCeiling(key.first, node)) {
            switch (compare (cur.element, key.first))
            case (larger) {
                return firstTerminalNode(keyAccumulator, cur);
            }        
            case (equal) {
                if (nonempty rest = key.rest) {
                    keyAccumulator.add(cur.element);
                    if (exists middle = cur.middle) {
                        value t = ceiling(rest, keyAccumulator, middle);
                        if (t exists) {
                            return t;
                        }
                        else {
                            // the element in node `cur` is too small,
                            // try an alternative node with a larger element   
                            keyAccumulator.deleteLast();
                            if (exists alt = bstStrictCeiling(key.first, 
                                                              node)) {
                                return if (alt === cur) then null
                                       else firstTerminalNode(keyAccumulator,
                                                              alt);
                            }
                            else {
                                return null;
                            }
                        }
                    }
                    else {
                        // the element in node `cur` is too small,
                        // try an alternative node with a larger element   
                        if (exists alt = bstStrictCeiling(key.first, node)) {
                            return if (alt === cur) then null
                                   else firstTerminalNode(keyAccumulator, alt);
                        }
                        else {
                            return null;
                        }
                    }
                }
                else { // key.rest is empty
                    if (cur.terminal) {
                        keyAccumulator.add(cur.element);
                        return cur;
                    }
                    else {
                        // `key` is a proper prefix of the key in this 
                        // tree path, so all keys further down along any 
                        // continuation of this path are greater (longer)
                        // than `key`. Return the smallest one. 
                        return firstTerminalNode(keyAccumulator, cur);
                    }
                }
            }        
            case (smaller) {
                "cannot happen"
                assert(false);
            }        
        }
        else {
            return null;
        }
    }
    
    "Lexicographically compares two keys. Returns `smaller` if `key1 < key2`, 
     `equal` if `key1 == key2`, and `larger` if `key1 > key2`."
    shared Comparison compareKeys(Key key1, Key key2){
        variable Key k1 = key1;
        variable Key k2 = key2;
        variable Comparison result = compare(key1.first, key2.first);
        while (result == equal) {
            value r1 = k1.rest;
            value r2 = k2.rest;
            if (nonempty r1, nonempty r2) {
                k1 = r1;
                k2 = r2;
                result = compare(k1.first, k2.first);                
            }
            else {
                break;
            }
        }
        return (if (result != equal)  then result 
                else if (k2.rest nonempty) then smaller
                else if (k1.rest nonempty) then larger
                else equal);
    }
    
    shared actual {<Key->Item>*} higherEntries(Key key)
            => object satisfies {<Key->Item>*} {
                value keyAccumulator = ArrayList<KeyElement>();
                value node = ceiling(key, keyAccumulator, root);
                if (node exists) {
                    keyAccumulator.deleteLast();
                }
                iterator() => EntryIterator(keyAccumulator, node);
            };
    
    shared actual {<Key->Item>*} lowerEntries(Key key)
            => object satisfies {<Key->Item>*} {
                value keyAccumulator = ArrayList<KeyElement>();
                value node = floor(key, keyAccumulator, root);
                if (node exists) {
                    keyAccumulator.deleteLast();
                }
                iterator() => ReverseEntryIterator(keyAccumulator, node);
            };
    
    
    shared actual {<Key->Item>*} ascendingEntries(Key from, Key to)
            => higherEntries(from).takeWhile(
                    (entry) => compareKeys(entry.key,to) != larger);
    
    
    shared actual {<Key->Item>*} descendingEntries(Key from, Key to)
            => lowerEntries(from).takeWhile(
                    (entry) => compareKeys(entry.key,to) != smaller);
    
    shared actual TernaryTreeMap<KeyElement,Item> measure(Key from, 
                                                          Integer length)
            => createAnotherMap(higherEntries(from).take(length), compare);
    
    shared actual TernaryTreeMap<KeyElement,Item> span(Key from, Key to)
            => let (reverse = compareKeys(from,to)==larger)
                createAnotherMap { 
                    entries = reverse then descendingEntries(from,to) 
                                      else ascendingEntries(from,to);
                    compare(KeyElement x, KeyElement y) 
                            => reverse then compare(y,x)
                                       else compare(x,y); 
                };
    
    shared actual TernaryTreeMap<KeyElement,Item> spanFrom(Key from)
            => createAnotherMap(higherEntries(from), compare);
    
    shared actual TernaryTreeMap<KeyElement,Item> spanTo(Key to)     
            => createAnotherMap(
                    takeWhile((entry) => compareKeys(entry.key,to) != larger), 
                    compare);
    
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
