import herd.reverbel.prefixmap { TernaryTreeMap, TernarySplayTreeMap }
import ceylon.test { test, assertTrue, assertFalse, 
                     assertEquals, assertNotEquals }
import ceylon.file { ... }

[Character+] toSequence(String nonEmptyString) {
    //value seq = [ for (c in nonEmptyString) c ];
    value seq = nonEmptyString.sequence();
    "parameter `nonEmptyString` is supposed to be a non-empty String"
    assert (nonempty seq);
    return seq; 
}

String toString([Character+] charSeq) {
    value strBuilder = StringBuilder();
    for (c in charSeq) {
        strBuilder.appendCharacter(c);
    }
    return strBuilder.string;
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
    print(m);
    n = m.get(toSequence("dOnUt"));
    print(n);
    
    print(m.first);
    print(m.last);
    
    value x15 = TernaryTreeMap({ toSequence("X")-> 15 });
    print(x15.first);
    print(x15.last);
    
    value aaa = TernaryTreeMap({ toSequence("a")-> 1, toSequence("ab")-> 2, toSequence("abc")-> 3});
    print(aaa.first);
    print(aaa.last);

    print("---------------");
    value it = aaa.iterator();
    while (!is Finished next = it.next()) {
        print(next);
    }
    
    print("---------------");
    print(m);
    value iter = m.iterator();
    while (!is Finished next = iter.next()) {
        print(next);
    }
    
    print("=========================================================================");
    print(m.higherEntries(toSequence("bat")));
    
    print("=========================================================================");
    print(m.higherEntries(toSequence("bates")));
    
    print("=========================================================================");
    print(m.higherEntries(toSequence("dont")));
    
    print("=========================================================================");
    print(m.lowerEntries(toSequence("dont")));

    print("*************************************************************************");    
    print(m);
    print("\n");
    print("\n");
    print("\n");
    print("\n");
    print("*************************************************************************");    
    print(m.higherEntries(toSequence("as")));
    print("\n");
    print("\n");
    print("\n");
    print("\n");
    print("*************************************************************************");    
    print(m.lowerEntries(toSequence("z")));
    print("\n");
    print("\n");
    print("\n");
    print("\n");
    print(aaa);
    print(aaa.lowerEntries(toSequence("z")));    
    print("\n");
    print("\n");
    print("\n");
    print("\n");
    
    value ab = TernaryTreeMap({ toSequence("a")-> 1, toSequence("ab")-> 2});
    print(ab);
    print("\n");
    print("\n");
    print(ab.lowerEntries(toSequence("z")));    
}

shared test void testWithFullDictionary() {
    value inputFilePath = parsePath("/home/reverbel/american-english.shuffled");
    if (is File inputFile = inputFilePath.resource) {
        value outputFilePath = home.childPath("american-english.iterated");
        value toDelete = outputFilePath.resource;
        if (is ExistingResource toDelete) {
            toDelete.delete();
        }
        value loc = outputFilePath.resource;
        assert (is Nil loc);
        value outputFile = loc.createFile();
        
        value outputFilePath2 = home.childPath("american-english.reverse-iterated");
        value toDelete2 = outputFilePath2.resource;
        if (is ExistingResource toDelete2) {
            toDelete2.delete();
        }
        value loc2 = outputFilePath2.resource;
        assert (is Nil loc2);
        value outputFile2 = loc2.createFile();

        
        try (reader = inputFile.Reader(), writer = outputFile.Overwriter(),
                                          writer2 = outputFile2.Overwriter()) {
            value map = TernaryTreeMap<Character, Integer>();
            while (exists word = reader.readLine()) { 
                map.put(toSequence(word), word.size);
            }
            for (entry in map) {
                writer.writeLine(toString(entry.key));  
            }
            //map.printNodes();
            if (exists last = map.last) {
                for (entry in map.lowerEntries(last.key)) {
                    writer2.writeLine(toString(entry.key));  
                }
            }
        }
    }
    else {
        print("input file does not exist");
    }
}

shared test void testTernarySplayTreeMap() {
    value map = TernarySplayTreeMap<Character, Integer>();
    variable Integer? n;
    
    value strings = {"bog", "at", "as", "bat", "bats", "boy", "day", "cats", "caste", "donut", "dog", "door"};
    for (str in strings) {
        n = map.put(toSequence(str), str.size);
        print(n);
        print(map);
        map.printNodes();
    }
    map.clear();
    value moreStrings = {"regret", "ultra's", "insinuating", "Charlotte's", "stakeouts"};
    for (str in moreStrings) {
        n = map.put(toSequence(str), str.size);
        //print(n);
        //print(map);
        //map.printNodes();
    }
    print("-----------------------------------------------------");
    map.printNodes();
    print("-----------------------------------------------------");
    map.clear();
    value yetMoreStrings = {"escapade", "es"};
    for (str in yetMoreStrings) {
        n = map.put(toSequence(str), str.size);
        print(map);
        map.printNodes();
    }
}

shared test void testTernarySplayTreeMapWithFullDictionary() {
    //value inputFilePath = parsePath("/usr/share/dict/american-english");
    value inputFilePath = parsePath("/home/reverbel/american-english.shuffled");
    if (is File inputFile = inputFilePath.resource) {
        value outputFilePath = home.childPath("american-english.splay-tree-iterated");
        value toDelete = outputFilePath.resource;
        if (is ExistingResource toDelete) {
            toDelete.delete();
        }
        value loc = outputFilePath.resource;
        assert (is Nil loc);
        value outputFile = loc.createFile();
        
        value outputFilePath2 = home.childPath("american-english.splay-tree-reverse-iterated");
        value toDelete2 = outputFilePath2.resource;
        if (is ExistingResource toDelete2) {
            toDelete2.delete();
        }
        value loc2 = outputFilePath2.resource;
        assert (is Nil loc2);
        value outputFile2 = loc2.createFile();
        
        
        try (reader = inputFile.Reader(), writer = outputFile.Overwriter(),
            writer2 = outputFile2.Overwriter()) {
            value map = TernarySplayTreeMap<Character, Integer>();
            while (exists word = reader.readLine()) {
                map.put(toSequence(word), word.size);
            }
            print("``map.size`` entries");
            for (entry in map) {
                writer.writeLine(toString(entry.key));  
            }
            if (exists last = map.last) {
                for (entry in map.lowerEntries(last.key)) {
                    writer2.writeLine(toString(entry.key));  
                }
            }
        }
    }
    else {
        print("input file does not exist");
    }
}
