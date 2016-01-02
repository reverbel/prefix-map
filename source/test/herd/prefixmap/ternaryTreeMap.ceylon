import herd.prefixmap { TernarySearchTreeMap,
                        TernarySplayTreeMap }
import ceylon.test { test, assertTrue, assertFalse, 
                     assertEquals, assertNotEquals }
import ceylon.file { ... }

"Converts a non-empty `String` in `Character` sequence."
shared [Character+] toSequence(String nonEmptyString) {
    value seq = nonEmptyString.sequence();
    "parameter `nonEmptyString` is supposed to be a non-empty String"
    assert (nonempty seq);
    return seq; 
}

"Converts a `Character` stream in `String`."
shared String toString({Character*} charStream) {
    value strBuilder = StringBuilder();
    for (c in charStream) {
        strBuilder.appendCharacter(c);
    }
    return strBuilder.string;
}

shared test void testEmptyTernaryTreeMap() {
    value map = TernarySearchTreeMap<Character, String, Integer>(toString);
    assertTrue(map.empty);
}

shared test void testSingleEntryTernaryTreeMap() {
    value map = TernarySearchTreeMap<Character, String, Integer>(toString);
    value key = "0123456789";
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
        print(keyPrefix);
        assertTrue(map.hasKeyWithPrefix(toString(keyPrefix)));
        for (k in map.keysWithPrefix(keyPrefix)) {
            assertEquals(k, key);
        }
        for (entry in map.entriesWithPrefix(keyPrefix)) {
            assertEquals(entry, key->key.size);
        }
    }
    assertFalse(map.hasKeyWithPrefix("12345"));
    
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

shared test void testMultipleEntryTernaryTreeMap() {
    value map = TernarySearchTreeMap<Character, String, Integer>(toString);
    variable Integer? n;
    
    value strings = {"bog", "at", "as", "bat", "bats", "boy", "day", "cats", "caste", "donut", "dog", "door"};
    for (str in strings) {
        n = map.put(str, str.size);
        print(n);
        print(map);
        map.printNodes();
    }
    value originalMap = map.clone();
    assertEquals(map, originalMap);
    assertEquals(map.hash, originalMap.hash);
    
    n = map.remove("cast");
    print(n);
    print(map);
    
    //n = map.remove("caste");
    n = map.remove("cats");
    print(n);
    print(map);
    map.printNodes();
    
    n = map.remove("donut");
    print(n);
    print(map);
    map.printNodes();
    
    n = map.remove("day");
    print(n);
    print(map);
    map.printNodes();
    
    print(if (map != originalMap) then "map changed" else "");
    print(originalMap);
    originalMap.printNodes();
    print(originalMap.size);
    
    value m = TernarySearchTreeMap {
        toKey = toString;
        entries = { for (str in strings) str -> str.size };
        Comparison compare(Character c1, Character c2) => c1.lowercased.compare(c2.lowercased);
    };
    print(m);
    n = m.get("dOnUt");
    print(n);
    
    print(m.first);
    print(m.last);
    
    value x15 = TernarySearchTreeMap(toString, { "X"-> 15 });
    print(x15.first);
    print(x15.last);
    
    value aaa = TernarySearchTreeMap(toString, { "a"-> 1, "ab"-> 2, "abc"-> 3});
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
    print(m.higherEntries("bat"));
    
    print("=========================================================================");
    print(m.higherEntries("bates"));
    
    print("=========================================================================");
    print(m.higherEntries("dont"));
    
    print("=========================================================================");
    print(m.lowerEntries("dont"));

    print("*************************************************************************");    
    print(m);
    print("\n");
    print("\n");
    print("\n");
    print("\n");
    print("*************************************************************************");    
    print(m.higherEntries("as"));
    print("\n");
    print("\n");
    print("\n");
    print("\n");
    print("*************************************************************************");    
    print(m.lowerEntries("z"));
    print("\n");
    print("\n");
    print("\n");
    print("\n");
    print(aaa);
    print(aaa.lowerEntries("z"));    
    print("\n");
    print("\n");
    print("\n");
    print("\n");
    
    value ab = TernarySearchTreeMap(toString, { "a"-> 1, "ab"-> 2});
    print(ab);
    print("\n");
    print("\n");
    print(ab.lowerEntries("z"));    
}

shared test void testTernaryTreeMapWithFullDictionary() {
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
            value map = TernarySearchTreeMap<Character, String, Integer>(toString);
            while (exists word = reader.readLine()) { 
                map.put(word, word.size);
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

shared test void testSingleEntryTernarySplayTreeMap() {
    value map = TernarySplayTreeMap<Character, String, Integer>(toString);
    value key = "0123456789";
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
        print(keyPrefix);
        assertTrue(map.hasKeyWithPrefix(toString(keyPrefix)));
        for (k in map.keysWithPrefix(keyPrefix)) {
            assertEquals(k, key);
        }
        for (entry in map.entriesWithPrefix(keyPrefix)) {
            assertEquals(entry, key->key.size);
        }
    }
    assertFalse(map.hasKeyWithPrefix("12345"));
    
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

shared test void testTernarySplayTreeMap() {
    value map = TernarySplayTreeMap<Character, String, Integer>(toString);
    variable Integer? n;
    
    value strings = {"bog", "at", "as", "bat", "bats", "boy", "day", "cats", "caste", "donut", "dog", "door"};
    for (str in strings) {
        n = map.put(str, str.size);
        print(n);
        print(map);
        map.printNodes();
    }
    map.clear();
    value moreStrings = {"regret", "ultra's", "insinuating", "Charlotte's", "stakeouts"};
    for (str in moreStrings) {
        n = map.put(str, str.size);
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
        n = map.put(str, str.size);
        print(map);
        map.printNodes();
    }
}

shared test void testMultipleEntryTernarySplayTreeMap() {
    value map = TernarySplayTreeMap<Character, String, Integer>(toString);
    variable Integer? n;
    
    value strings = {"bog", "at", "as", "bat", "bats", "boy", "day", "cats", "caste", "donut", "dog", "door"};
    for (str in strings) {
        n = map.put(str, str.size);
        print(n);
        print(map);
        map.printNodes();
    }
    value originalMap = map.clone();
    assertEquals(map, originalMap);
    assertEquals(map.hash, originalMap.hash);
    
    n = map.remove("cast");
    print(n);
    print(map);
    
    //n = map.remove("caste");
    n = map.remove("cats");
    print(n);
    print(map);
    map.printNodes();
    
    print("will remove \"donut\" -------------------------------------------");
    n = map.remove("donut");
    print(n);
    print(map);
    map.printNodes();
    
    print("will remove \"day\" ---------------------------------------------");
    n = map.remove("day");
    print(n);
    print(map);
    map.printNodes();
    
    print("will remove \"caste\" -------------------------------------------");
    n = map.remove("caste");
    print(n);
    print(map);
    map.printNodes();
    
    print(if (map != originalMap) then "map changed" else "");
    print(originalMap);
    originalMap.printNodes();
    print(originalMap.size);
    
    value m = TernarySplayTreeMap {
        toKey = toString;
        entries = { for (str in strings) str -> str.size };
        Comparison compare(Character c1, Character c2) => c1.lowercased.compare(c2.lowercased);
    };
    print(m);
    n = m.get("dOnUt");
    print(n);
    
    print(m.first);
    print(m.last);
    
    value x15 = TernarySplayTreeMap(toString, { "X"-> 15 });
    print(x15.first);
    print(x15.last);
    
    value aaa = TernarySplayTreeMap(toString, { "a"-> 1, "ab"-> 2, "abc"-> 3});
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
    print(m.higherEntries("bat"));
    
    print("=========================================================================");
    print(m.higherEntries("bates"));
    
    print("=========================================================================");
    print(m.higherEntries("dont"));
    
    print("=========================================================================");
    print(m.lowerEntries("dont"));
    
    print("*************************************************************************");    
    print(m);
    print("\n");
    print("\n");
    print("\n");
    print("\n");
    print("*************************************************************************");    
    print(m.higherEntries("as"));
    print("\n");
    print("\n");
    print("\n");
    print("\n");
    print("*************************************************************************");    
    print(m.lowerEntries("z"));
    print("\n");
    print("\n");
    print("\n");
    print("\n");
    print(aaa);
    print(aaa.lowerEntries("z"));    
    print("\n");
    print("\n");
    print("\n");
    print("\n");
    
    value ab = TernarySplayTreeMap(toString, { "a"-> 1, "ab"-> 2});
    print(ab);
    print("\n");
    print("\n");
    print(ab.lowerEntries("z"));    
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
            value map = TernarySplayTreeMap<Character, String, Integer>(toString);
            while (exists word = reader.readLine()) {
                map.put(word, word.size);
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

shared test void testMultipleEntryTernaryTree() {
    //value map = TernarySearchTreeMap<Character, String, Integer>(toString);
    value map = TernarySplayTreeMap<Character, String, Integer>(toString);
    variable Integer? n;
    
    value strings = {"bog", "at", "as", "bat", "bats", "boy", "day", "cats", "caste", "donut", "dog", "door"};
    for (str in strings) {
        n = map.put(str, str.size);
        print(n);
        print(map);
    }
    value originalMap = map.clone();
    assertEquals(map, originalMap);
    assertEquals(map.hash, originalMap.hash);
    
    n = map.remove("cast");
    print(n);
    print(map);
    
    //n = map.remove("caste");
    n = map.remove("cats");
    print(n);
    print(map);
    
    print("will remove \"donut\" -------------------------------------------");
    n = map.remove("donut");
    print(n);
    print(map);
    
    print("will remove \"day\" ---------------------------------------------");
    n = map.remove("day");
    print(n);
    print(map);
    
    print("will remove \"caste\" -------------------------------------------");
    n = map.remove("caste");
    print(n);
    print(map);
    
    print(if (map != originalMap) then "map changed" else "");
    print(originalMap);
    print(originalMap.size);
    
}

