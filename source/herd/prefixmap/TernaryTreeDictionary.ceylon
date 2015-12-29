import ceylon.collection {
    MutableMap
}
"A mutable [[PrefixDictionary]] backed by a _ternary search tree_ whose 
 keys are non-empty [[String]] instances. Map entries are mantained in
 lexicographic order of keys, from the smallest to the largest key. 
 
 The function [[wrapAsDictionary]] creates [[TernaryTreeDictionary]] 
 instances. It receives a [[TernaryTreeMap]]`<Character,Item>` parameter
 and returns a [[TernaryTreeDictionary]]`<Item>` instance that wraps that
 parameter. The lexicographic ordering of the [[String]] keys of the 
 returned dictionary relies on the [[Character]] comparison function used
 by the wrapped map."
see (`interface PrefixDictionary`,
     `interface Map`, `class Entry`, `interface Comparable`,
     `interface PrefixMap`, `interface TernaryTreeMap`,
      `function wrapAsDictionary`)
tagged ("Collections")
by ("Francisco Reverbel")
shared interface TernaryTreeDictionary<Item>
        satisfies PrefixDictionary<Item> 
                  & MutableMap<String, Item> {
}

class TernaryTreeMapWrapper<Item>(TernaryTreeMap<Character, Item> innerMap)
        satisfies TernaryTreeDictionary<Item> {
    
    shared actual {<String->Item>*} ascendingEntries(String from, String to) 
            => { for (k->i in innerMap.ascendingEntries(toSequence(from),
                                                        toSequence(to)))
                    toString(k)->i };
    
    shared actual void clear() {
        innerMap.clear();
    }
    
    shared actual TernaryTreeDictionary<Item> clone() 
            => wrapAsDictionary<Item>(innerMap.clone());
    
    shared actual Boolean defines(Object key) 
            => if (is String key) 
                then innerMap.defines(toSequence(key))
                else false;
    
    shared actual {<String->Item>*} descendingEntries(String from, String to)
            => { for (k->i in innerMap.descendingEntries(toSequence(from),
                                                         toSequence(to)))
                    toString(k)->i };
    
    shared actual {<String->Item>*} entriesWithPrefix(String prefix) 
            => { for (k->i in innerMap.entriesWithPrefix(toSequence(prefix)))
                    toString(k)->i };
    
    shared actual Boolean empty
            => innerMap.empty;
    
    shared actual <String->Item>? first
            => let (innerFirst = innerMap.first)
                if (exists innerFirst) 
                then let (k->i = innerFirst) toString(k)->i
                else null;
    
    shared actual Item? get(Object key) 
            => if (is String key) then innerMap.getByIterableKey(key) else null;
    
    shared actual <String->Item>? last
            => let (innerLast = innerMap.last)
                if (exists innerLast) 
                then let (k->i = innerLast) toString(k)->i
                else null;
    
    shared actual Boolean hasKeyWithPrefix(String prefix) 
            => innerMap.hasKeyWithPrefix(toSequence(prefix));
    
    shared actual {<String->Item>*} higherEntries(String key)
            => { for (k->i in innerMap.higherEntries(toSequence(key))) 
                    toString(k)->i };
    
    shared actual Iterator<String->Item> iterator() 
            => let (innerIterator = innerMap.iterator())
                object satisfies Iterator<String->Item> {
                    shared actual <String->Item>|Finished next()
                            => let (entry = innerIterator.next())
                                if (is Finished entry) 
                                    then finished
                                    else let (k->i = entry) toString(k)->i;
                };
    
    shared actual {String*} keysWithPrefix(String prefix) 
            => { for (key in innerMap.keysWithPrefix(toSequence(prefix))) 
                    toString(key) };
    
    shared actual {<String->Item>*} lowerEntries(String key) 
            => { for (k->i in innerMap.lowerEntries(toSequence(key))) 
                    toString(k)->i };
    
    shared actual PrefixDictionary<Item> measure(String from, Integer length)
            => wrapAsDictionary(innerMap.measure(toSequence(from), length));
    
    shared actual Item? put(String key, Item item) 
            => innerMap.put(toSequence(key), item);
    
    shared actual Item? remove(String key)
            => innerMap.remove(toSequence(key));
    
    shared actual Integer size
            => innerMap.size;
    
    shared actual PrefixDictionary<Item> span(String from, String to)
            => wrapAsDictionary(innerMap.span(toSequence(from), 
                                              toSequence(to)));
    
    shared actual PrefixDictionary<Item> spanFrom(String from)
            => wrapAsDictionary(innerMap.spanFrom(toSequence(from))); 
    
    shared actual PrefixDictionary<Item> spanTo(String to)
            => wrapAsDictionary(innerMap.spanTo(toSequence(to))); 
    
    shared actual Boolean equals(Object that)
            => (super of Map<String, Item>).equals(that);
    
    shared actual Integer hash
            => (super of Map<String, Item>).hash;
}

"Converts a non-empty `String` in `Character` sequence."
shared [Character+] toSequence(String nonEmptyString) {
    value seq = nonEmptyString.sequence();
    "parameter `nonEmptyString` is supposed to be a non-empty String"
    assert (nonempty seq);
    return seq; 
}

"Converts a non-empty `Character` sequence in `String`."
shared String toString([Character+] charSeq) {
    value strBuilder = StringBuilder();
    for (c in charSeq) {
        strBuilder.appendCharacter(c);
    }
    return strBuilder.string;
}

"Returns a [[TernaryTreeDictionary]] instance that wraps the given `innerMap`."
see(`interface TernaryTreeDictionary`)
shared TernaryTreeDictionary<Item> 
        wrapAsDictionary<Item>(TernaryTreeMap<Character, Item> innerMap)
                => TernaryTreeMapWrapper(innerMap);
