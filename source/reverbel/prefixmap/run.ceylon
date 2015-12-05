"Run the module `reverbel.prefixmap`."
[Character+] toSequence(String nonEmptyString) {
    value seq = [ for (c in nonEmptyString) c ];
    assert (nonempty seq);
    return seq; 
}

shared void run() {
    value map = TernaryTreeMap<Character, Integer>();
    //value s = "Francisco Reverbel";
    //value seq = [ for (c in s) c ];
    //for (c in seq) { print(c); }
    //print("----");
    //for (c in seq) { print(c); }
    //assert (is [Character+] seq);

    variable String s;
    variable Integer? n;
    
    s = "12345678";
    map.put(toSequence(s), s.size);
    n = map.get(toSequence(s));
    print(n);
    print(map);
    map.printNodes();
    
    //s = "ba";
    //map.put(toSequence(s), s.size);
    //n = map.get(toSequence(s));
    //print(n);
    //print(map);
    //map.printNodes();
    
    s = "bac";
    map.put(toSequence(s), s.size);
    n = map.get(toSequence(s));
    print(n);
    print(map);
    map.printNodes();
    
    s = "bacpqrstuvwxyz";
    map.put(toSequence(s), s.size);
    n = map.get(toSequence(s));
    print(n);
    print(map);
    map.printNodes();
    
    print("removal test");
    n = map.remove(toSequence(s));
    print(n);
    print(map);
    map.printNodes();
    n = map.remove(toSequence("bac"));
    print(n);
    print(map);
    map.printNodes();
    n = map.remove(toSequence("12345678"));
    print(n);
    print(map);
    map.printNodes();
    
    
    //map.put(toSequence("bac"), 3);
    //map.put(toSequence("bacana"), 6);
    //print(map.keys);
    //print(map.get(toSequence("baa")));
    
    value strings = {"bog", "at", "as", "bat", "bats", "boy", "day", "cats", "caste", "donut", "dog", "door"};
    for (str in strings) {
        n = map.put(toSequence(str), str.size);
        print(n);
        print(map);
        map.printNodes();  
    }
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
    
}