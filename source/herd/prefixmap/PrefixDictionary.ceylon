import ceylon.collection { SortedMap }

"A [[SortedMap]] whose keys are non-empty strings.
 `PrefixDictionary` supports the following prefix queries:
 - Does the map contain some [[Entry]] whose key has a given prefix?
 - Retrieve all the keys of the map that have a given prefix.
 - Retrieve all the entries in the map whose keys have a given prefix.
 A [[PrefixDictionary]]`<Item>` is similar to a
 [[PrefixMap]]`<Character,Item>`, with the difference that in the former 
 the keys have type `String`, and in the latter the keys have type 
 `[Character+]`."
see (`interface SortedMap`, 
     `interface Ranged`, 
     `interface Map`, 
     `interface Comparable`, 
     `class Entry`,
     `interface PrefixMap`)
tagged ("Collections")
by ("Francisco Reverbel")
shared interface PrefixDictionary<out Item>
        satisfies SortedMap<String,Item>
                  & Ranged<String, String->Item, PrefixDictionary<Item>> {
    
    "Returns `true` if this map has a key with the given prefix, or
     `false` otherwise."
    shared formal Boolean hasKeyWithPrefix(String prefix);
    
    "Returns a stream containing all the keys with the given prefix
     that are present in this map."
    shared formal {String*} keysWithPrefix(String prefix);
    
    "Returns a stream with all the entries in this map whose keys have the
     given prefix."
    shared formal {<String->Item>*} entriesWithPrefix(String prefix);
    
}
