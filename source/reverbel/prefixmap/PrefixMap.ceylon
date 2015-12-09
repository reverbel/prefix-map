"A [[Map]] whose keys are sequences of [[Comparable]] elements.
 The entries in a `PrefixMap` are mantained in lexicographic order of 
 keys. `PrefixMap` supports the following prefix queries:
 - Does the map contain some [[Entry]] whose key has a given prefix?
 - Retrieve all the keys of the map that have a given prefix.
 - Retrieve all the entries in the map whose keys have a given prefix."
see (`interface Map`, `interface Comparable`, `class Entry`)
tagged ("Collections")
by ("Francisco Reverbel")
shared interface PrefixMap<out KeyElement, out Item>
        satisfies Map<[KeyElement+], Item>
        given KeyElement satisfies Comparable<KeyElement> {
    
    "The type of the keys of this `PrefixMap`. A `Key` is a non-empty 
     sequence of `KeyElement`s. (`Key` is an alias for `[KeyElement+]`.)"
    shared interface Key => [KeyElement+];
    
    "Returns `true` if this map has a key with the given prefix, or `false`
     otherwise."
    shared formal Boolean hasKeyWithPrefix(Object prefix);
    
    "Returns a stream with all the keys of this map with the given prefix."
    shared formal {Key*} keysWithPrefix(Object prefix);
    
    "Returns a stream with all the entries in this map whose keys have
     the given prefix."
    shared formal {<Key->Item>*} entriesWithPrefix(Object prefix);
    
    "Returns a non-empty stream with all the keys of this map with the 
     given prefix, or `null` if no such key appears in this map."
    shared formal {Key+}? oneOrMoreKeysWithPrefix(Object prefix);
    
    "Returns a non-empty stream with all the entries in the map whose keys
     have the given prefix, or `null` if the map does not contain such an 
     entry."
    shared formal {<Key->Item>+}? oneOrMoreEntriesWithPrefix(Object prefix);
}
