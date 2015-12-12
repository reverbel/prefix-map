import herd.reverbel.prefixmap { TernaryTreeMap }
import ceylon.test { test, assertTrue, assertFalse, 
                     assertEquals, assertNotEquals }

[Character+] toSequence(String nonEmptyString) {
    value seq = [ for (c in nonEmptyString) c ];
    "parameter `nonEmptyString` is supposed to be a non-empty String"
    assert (nonempty seq);
    return seq; 
}

shared test void testEmptyTreeMap() {
    value map = TernaryTreeMap<Character, Integer>();
    assertTrue(map.empty);
}

shared test void testSingleEntryTreeMap() {
    value map = TernaryTreeMap<Character, Integer>();
    value key = toSequence("0123456789");
    map.put(key, key.size);
    assertFalse(map.empty);
    assertEquals(map.size, 1);
    assertTrue(map.defines(key));
    assertEquals(map.get(key), key.size);
    for (entry in map) {
        assertEquals(entry, key->key.size);
    }
    for (k in map.keys) {
        assertEquals(k, key);
    }
    for (i in map.items) {
        assertEquals(i, key.size);
    }
    variable Character[] keyPrefix = [];
    for (c in '0'..'9') {
        keyPrefix = keyPrefix.append<Character>([c]);
        //print(keyPrefix);
        assertTrue(map.hasKeyWithPrefix(keyPrefix));
        for (k in map.keysWithPrefix(keyPrefix)) {
            assertEquals(k, key);
        }
        for (entry in map.entriesWithPrefix(keyPrefix)) {
            assertEquals(entry, key->key.size);
        }
    }
    assertFalse(map.hasKeyWithPrefix(toSequence("12345")));
    
    value clonedMap = map.clone();
    assertEquals(map, clonedMap);
    
    map.remove(key);
    assertTrue(map.empty);
    assertEquals(map.size, 0);
    assertFalse(map.defines(key));
    
    assertNotEquals(map, clonedMap);
    clonedMap.clear();
    assertEquals(map, clonedMap);
}

shared test void testMultipleEntryTreeMap() {
    value map = TernaryTreeMap<Character, Integer>();
    variable Integer? n;
    
    value strings = {"bog", "at", "as", "bat", "bats", "boy", "day", "cats", "caste", "donut", "dog", "door"};
    for (str in strings) {
        n = map.put(toSequence(str), str.size);
        print(n);
        print(map);
        map.printNodes();
    }
    value originalMap = map.clone();
    assertEquals(map, originalMap);
    assertEquals(map.hash, originalMap.hash);
    
    n = map.remove(toSequence("cast"));
    print(n);
    print(map);
    
    //n = map.remove(toSequence("caste"));
    n = map.remove(toSequence("cats"));
    print(n);
    print(map);
    map.printNodes();
    
    n = map.remove(toSequence("donut"));
    print(n);
    print(map);
    map.printNodes();
    
    n = map.remove(toSequence("day"));
    print(n);
    print(map);
    map.printNodes();
    
    print(if (map != originalMap) then "map changed" else "");
    print(originalMap);
    originalMap.printNodes();
    print(originalMap.size);
    
    value m = TernaryTreeMap {
        entries = { for (str in strings) toSequence(str) -> str.size };
        Comparison compare(Character c1, Character c2) => c1.lowercased.compare(c2.lowercased);
    };
    print(map);
    n = m.get(toSequence("dOnUt"));
    print(n);
        
}
