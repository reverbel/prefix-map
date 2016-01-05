import herd.prefixmap { TernarySearchTreeMap, TernarySplayTreeMap }
import ceylon.test { test, assertTrue, assertFalse, 
                     assertEquals, assertNotEquals }
import ceylon.file { File, parsePath, home, ExistingResource, Nil }
import ceylon.process { Process, createProcess, currentOutput, currentError }
import ceylon.collection { ArrayList }

"Converts a non-empty `String` in `Character` sequence."
[Character+] toSequence(String nonEmptyString) {
    value seq = nonEmptyString.sequence();
    "parameter `nonEmptyString` is supposed to be a non-empty String"
    assert (nonempty seq);
    return seq; 
}

"Converts a `Character` stream in `String`."
String toString({Character*} charStream) {
    value strBuilder = StringBuilder();
    for (c in charStream) {
        strBuilder.appendCharacter(c);
    }
    return strBuilder.string;
}

shared test void testEmptyTernarySearchTreeMap() {
    value map = TernarySearchTreeMap<Character, String, Integer>(toString);
    assertTrue(map.empty);
}

shared test void testSingleEntryTernarySearchTreeMap() {
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

shared test void testMultipleEntryTernarySearchTreeMap() {
    value map = TernarySearchTreeMap<Character, String, Integer>(toString);
    variable String s;
    variable Integer? n;
    
    value strings = {"at", "as", "bat", "bats", "bog", "boy", "caste", "cats", "day", "dog", "donut", "door"};
    for (str in strings) {
        n = map.put(str, str.size);
        assert (n is Null);
    }
    value originalMap = map.clone();
    assertEquals(map, originalMap);
    assertEquals(map.hash, originalMap.hash);
    
    s = "cast"; // not a key in the map
    n = map.remove(s);
    assert (n is Null);
    assertEquals(map, originalMap);
    
    value keysRemoved = ArrayList<String>();
    void checkRemoval(String keyRemoved, Integer? itemRemoved) {
        assert (exists item = itemRemoved, item == keyRemoved.size);
        keysRemoved.add(keyRemoved);
        value auxMap = map.clone();
        for (str in keysRemoved) {
            value oldItem = auxMap.put(str, str.size);
            assert (oldItem is Null);
        }
        assertEquals(auxMap, originalMap);
        assertNotEquals(map, originalMap);
    }
            
    //s = "caste";
    s = "cats";
    n = map.remove(s);
    checkRemoval(s, n);
    
    s = "donut";
    n = map.remove(s);
    checkRemoval(s, n);
    
    s = "day";
    n = map.remove(s);
    checkRemoval(s, n);
    
    void checkSuccessfulGet(String key, Integer? item) {
        assert(exists i = item, i == key.size);
    }
    
    value m = TernarySearchTreeMap {
        toKey = toString;
        entries = { for (str in strings) str -> str.size };
        Comparison compare(Character c1, Character c2) => c1.lowercased.compare(c2.lowercased);
    };
    
    s = "BoG";
    n = m.get(s);
    checkSuccessfulGet(s, n);
    
    s = "CATS";
    n = m.get(s);
    checkSuccessfulGet(s, n);

    s = "dOnUt";
    n = m.get(s);
    checkSuccessfulGet(s, n);
    
    assertEquals(m.first, originalMap.first);
    assertEquals(m.last, originalMap.last);

    
    value x15 = TernarySearchTreeMap(toString, { "X"-> 15 });
    assertEquals(x15.first, "X"-> 15);
    assertEquals(x15.last, "X"-> 15);
    
    value aaa = TernarySearchTreeMap(toString, { "a"-> 1, "ab"-> 2, "abc"-> 3});
    assertEquals(aaa.first, "a"-> 1);
    assertEquals(aaa.last, "abc"-> 3);

    assertEquals(m.higherEntries("bat").sequence(), m.higherEntries("bab").sequence());
    assertEquals(m.higherEntries("bates").sequence(), m.higherEntries("bats").sequence());
    assertEquals(m.higherEntries("dont").sequence(), m.higherEntries("DONUT").sequence());
    assertEquals(m.lowerEntries("dont").sequence(), m.lowerEntries("DoG").sequence());
    assertEquals(m.higherEntries("as").sequence(), m.sequence());
    assertEquals(m.lowerEntries("z").sequence(), m.sequence().reversed);

}

shared test void testReverseIteratorOnTernarySearchTreeMap() {
    value map = TernarySearchTreeMap<Character, String, Integer>(toString);
    
    value strings = ["as", "at", "bat", "bats", "bog", "boy", "caste", "cats", "day", "dog", "donut", "door"];
    for (str in strings) {
        map.put(str, str.size);
    }
    value entries = map.sequence();
    for (str in strings) {
        value s1 = map.lowerEntries(str).sequence();
        value s2 = map.higherEntries(str).sequence().rest;
        value s3 = s1.reversed.append(s2);
        assertEquals(s3, entries);
    }
}

shared test void testTernarySearchTreeMapWithFullDictionary() {
    value inputFilePath = parsePath("/home/reverbel/datafiles/american-english.shuffled");
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
        
        Process process1 = createProcess { 
            command = "cmp";
            arguments = ["american-english.iterated", "/home/reverbel/datafiles/american-english.ordered"];
            path = home;
            output = currentOutput;
            error = currentError;
        };
        assertEquals(process1.waitForExit(), 0);
        
        Process process2 = createProcess { 
            command = "cmp";
            arguments = ["american-english.reverse-iterated", "/home/reverbel/datafiles/american-english.reverse-ordered"];
            path = home;
            output = currentOutput;
            error = currentError;
        };
        assertEquals(process2.waitForExit(), 0);
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

shared test void testMultipleEntryTernarySplayTreeMap() {
    value map = TernarySplayTreeMap<Character, String, Integer>(toString);
    variable String s;
    variable Integer? n;
    
    value strings = {"at", "as", "bat", "bats", "bog", "boy", "caste", "cats", "day", "dog", "donut", "door"};
    for (str in strings) {
        n = map.put(str, str.size);
        assert (n is Null);
    }
    value originalMap = map.clone();
    assertEquals(map, originalMap);
    assertEquals(map.hash, originalMap.hash);
    
    s = "cast"; // not a key in the map
    n = map.remove(s);
    assert (n is Null);
    assertEquals(map, originalMap);
    
    value keysRemoved = ArrayList<String>();
    void checkRemoval(String keyRemoved, Integer? itemRemoved) {
        assert (exists item = itemRemoved, item == keyRemoved.size);
        keysRemoved.add(keyRemoved);
        value auxMap = map.clone();
        for (str in keysRemoved) {
            value oldItem = auxMap.put(str, str.size);
            assert (oldItem is Null);
        }
        assertEquals(auxMap, originalMap);
        assertNotEquals(map, originalMap);
    }
    
    //s = "caste";
    s = "cats";
    n = map.remove(s);
    checkRemoval(s, n);
    
    s = "donut";
    n = map.remove(s);
    checkRemoval(s, n);
    
    s = "day";
    n = map.remove(s);
    checkRemoval(s, n);
    
    void checkSuccessfulGet(String key, Integer? item) {
        assert(exists i = item, i == key.size);
    }
    
    value m = TernarySplayTreeMap {
        toKey = toString;
        entries = { for (str in strings) str -> str.size };
        Comparison compare(Character c1, Character c2) => c1.lowercased.compare(c2.lowercased);
    };
    
    s = "BoG";
    n = m.get(s);
    checkSuccessfulGet(s, n);
    
    s = "CATS";
    n = m.get(s);
    checkSuccessfulGet(s, n);
    
    s = "dOnUt";
    n = m.get(s);
    checkSuccessfulGet(s, n);
    
    assertEquals(m.first, originalMap.first);
    assertEquals(m.last, originalMap.last);
    
    
    value x15 = TernarySplayTreeMap(toString, { "X"-> 15 });
    assertEquals(x15.first, "X"-> 15);
    assertEquals(x15.last, "X"-> 15);
    
    value aaa = TernarySplayTreeMap(toString, { "a"-> 1, "ab"-> 2, "abc"-> 3});
    assertEquals(aaa.first, "a"-> 1);
    assertEquals(aaa.last, "abc"-> 3);
    
    assertEquals(m.higherEntries("bat").sequence(), m.higherEntries("bab").sequence());
    assertEquals(m.higherEntries("bates").sequence(), m.higherEntries("bats").sequence());
    assertEquals(m.higherEntries("dont").sequence(), m.higherEntries("DONUT").sequence());
    assertEquals(m.lowerEntries("dont").sequence(), m.lowerEntries("DoG").sequence());
    assertEquals(m.higherEntries("as").sequence(), m.sequence());
    assertEquals(m.lowerEntries("z").sequence(), m.sequence().reversed);
    
}

shared test void testReverseIteratorOnTernarySplayTreeMap() {
    //value map = TernarySearchTreeMap<Character, String, Integer>(toString);
    value map = TernarySplayTreeMap<Character, String, Integer>(toString);
    
    value strings = ["as", "at", "bat", "bats", "bog", "boy", "caste", "cats", "day", "dog", "donut", "door"];
    for (str in strings) {
        map.put(str, str.size);
    }
    value entries = map.sequence();
    for (str in strings) {
        value s1 = map.lowerEntries(str).sequence();
        value s2 = map.higherEntries(str).sequence().rest;
        value s3 = s1.reversed.append(s2);
        assertEquals(s3, entries);
    }
}

shared test void testTernarySplayTreeMapWithFullDictionary() {
    value inputFilePath = parsePath("/home/reverbel/datafiles/american-english.shuffled");
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
        
        Process process1 = createProcess { 
            command = "cmp";
            arguments = ["american-english.splay-tree-iterated", "/home/reverbel/datafiles/american-english.ordered"];
            path = home;
            output = currentOutput;
            error = currentError;
        };
        assertEquals(process1.waitForExit(), 0);
        
        Process process2 = createProcess { 
            command = "cmp";
            arguments = ["american-english.splay-tree-reverse-iterated", "/home/reverbel/datafiles/american-english.reverse-ordered"];
            path = home;
            output = currentOutput;
            error = currentError;
        };
        assertEquals(process2.waitForExit(), 0);
    }
    else {
        print("input file does not exist");
    }
}

shared test void testBugFixOnTernarySplayTreeMap() {
    value map = TernarySplayTreeMap<Character, String, Integer>(toString);
    
    value someStrings = {"regret", "ultra's", "insinuating", "Charlotte's", "stakeouts"};
    for (str in someStrings) {
        map.put(str, str.size);
    }
    assertEquals(map.string, "{ Charlotte's->11, insinuating->11, regret->6, stakeouts->9, ultra's->7 }");
    map.clear();
    value moreStrings = {"escapade", "es"};
    for (str in moreStrings) {
        map.put(str, str.size);
    }
    assertEquals(map.string, "{ es->2, escapade->8 }");
}
