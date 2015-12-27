import ceylon.collection { SortedMap }

"A [[SortedMap]] whose keys are sequences of [[Comparable]] elements.
 `PrefixMap` supports the following prefix queries:
 - Does the map contain some [[Entry]] whose key has a given prefix?
 - Retrieve all the keys of the map that have a given prefix.
 - Retrieve all the entries in the map whose keys have a given prefix."
see (`interface SortedMap`, 
     `interface Ranged`, 
     `interface Map`, 
     `interface Comparable`, 
     `class Entry`)
tagged ("Collections")
by ("Francisco Reverbel")
shared interface PrefixMap<KeyElement, out Item>
        satisfies SortedMap<[KeyElement+],Item>
                  & Ranged<[KeyElement+],
                           [KeyElement+]->Item,
                           PrefixMap<KeyElement,Item>>
        given KeyElement satisfies Comparable<KeyElement> {
    
    "The type of the keys of this `PrefixMap`. A `Key` is a non-empty 
     sequence of `KeyElement`s. (`Key` is an alias for `[KeyElement+]`.)"
    shared interface Key => [KeyElement+];
    
    "Returns `true` if this map has a key with the given prefix, or
     `false` otherwise."
    shared formal Boolean hasKeyWithPrefix(Object prefix);
    
    "Returns a stream containing all the keys with the given prefix
     that are present in this map."
    shared formal {Key*} keysWithPrefix(Object prefix);
    
    "Returns a stream with all the entries in this map whose keys have the
     given prefix."
    shared formal {<Key->Item>*} entriesWithPrefix(Object prefix);
    
}
