import ceylon.collection { SortedMap }

"A [[SortedMap]] whose keys are streams of [[Comparable]] elements.
 `PrefixMap` supports the following prefix queries:
 - Does the map contain some [[Entry]] whose key has a given prefix?
 - Retrieve all the keys of the map that have a given prefix.
 - Retrieve all the entries in the map whose keys have a given prefix.
 
 An empty stream cannot used as a key. Whenever an empty stream appears
 in the place of a key parameter, an exception will be generated. Even
 though empty keys are disallowed, the key type is \`{KeyElement*}\`
 (rather than \`{KeyElement+}\`), in order to allow non-empty [[String]]
 instances to be used as keys."
see (`interface SortedMap`, 
     `interface Ranged`, 
     `interface Map`, 
     `interface Comparable`, 
     `class Entry`)
tagged ("Collections")
by ("Francisco Reverbel")
shared interface PrefixMap<KeyElement, out Item>
        satisfies SortedMap<{KeyElement*},Item>
                  & Ranged<{KeyElement*},
                           {KeyElement*}->Item,
                           PrefixMap<KeyElement,Item>>
        given KeyElement satisfies Comparable<KeyElement> {
    
    "The type of the keys of this `PrefixMap`. A `Key` is a  
     stream of `KeyElement`s. Even though `Key` is an alias for
     `{KeyElement*}`, valid keys are assumed to be non-empty."
    shared interface Key => {KeyElement*};
    
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
