shared interface PrefixMap<out KeyElement, out Item>
        satisfies Map<[KeyElement+], Item>
        given KeyElement satisfies Comparable<KeyElement> {
    
    shared interface Key => [KeyElement+];
    
    shared formal Boolean hasKeyWithPrefix(Object prefix);
    
    shared formal {Key*} keysWithPrefix(Object prefix);
    
    shared formal {<Key->Item>*} entriesWithPrefix(Object prefix);
    
    shared formal {Key+}? oneOrMoreKeysWithPrefix(Object prefix);
    
    shared formal {<Key->Item>+}? oneOrMoreEntriesWithPrefix(Object prefix);
}
