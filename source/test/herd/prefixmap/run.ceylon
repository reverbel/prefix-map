import herd.prefixmap { 
    TernarySearchTreeMap, TernarySplayTreeMap, wrapAsDictionary, toSequence
}
import ceylon.file { File, parsePath }
import ceylon.collection { ArrayList, TreeMap, HashMap }

void measureSearchTime(Map<String, Integer> map,
    ArrayList<String> keysToSearch, 
    Integer repetitions = 1) {
    variable Integer n = repetitions;
    variable Integer count = 0;
    variable Integer t = 0;
    //value t1 = system.nanoseconds;
    while (n > 0) {
        value iter = keysToSearch.iterator();
        while (is String key = iter.next()) {
            value t1 = system.nanoseconds;
            map.get(key);
            value t2 = system.nanoseconds;
            t += (t2 - t1);
            count++;
        }
        n--;
    }
    //value t2 = system.nanoseconds;
    //print("``(t2 - t1).float / (1000 * count)`` milliseconds");
    print("``t.float / (1000 * count)`` milliseconds");
}


"Run the module `prefixmap.perf.eval`."
shared void run() {
    //value inputFilePath = parsePath("/home/reverbel/american-english.shuffled");
    value inputFilePath = parsePath("/home/reverbel/find.output.txt");
    if (is File inputFile = inputFilePath.resource) {
        try (reader = inputFile.Reader()) {
            value keysToSearch = ArrayList<String>();
            value seqsToSearch = ArrayList<[Character+]>();
            variable Integer count = 0;
            variable Integer t = 0;
            while (exists word = reader.readLine()) {
                keysToSearch.add(word);
            }
            variable Integer n = 10;
            while (n > 0) {
                seqsToSearch.clear();
                for (key in keysToSearch) {
                    value t1 = system.nanoseconds;
                    value seq = toSequence(key);
                    value t2 = system.nanoseconds;
                    seqsToSearch.add(seq);
                    t += (t2 - t1);
                    count++;
                }
                n--;
            }
            process.write("toSequence: ");
            print("``t.float / (1000 * count)`` milliseconds");
        }
        try (reader = inputFile.Reader()) {
            value map = 
                    wrapAsDictionary(TernarySearchTreeMap<Character, Integer>());
            value keysToSearch = ArrayList<String>();
            while (exists word = reader.readLine()) { 
                map.put(word, word.size);
                keysToSearch.add(word);
            }
            process.write("get on TernarySearchTreeMap: ");
            measureSearchTime(map, keysToSearch, 10);
        }
        try (reader = inputFile.Reader()) {
            value map = 
                    wrapAsDictionary(TernarySplayTreeMap<Character, Integer>());
            value keysToSearch = ArrayList<String>();
            while (exists word = reader.readLine()) { 
                map.put(word, word.size);
                keysToSearch.add(word);
            }
            process.write("get on TernarySplayTreeMap: ");
            measureSearchTime(map, keysToSearch, 10);
        }
        try (reader = inputFile.Reader()) {
            value map = TreeMap<String, Integer>((s1, s2) => s1.compare(s2)); 
            value keysToSearch = ArrayList<String>();
            while (exists word = reader.readLine()) { 
                map.put(word, word.size);
                keysToSearch.add(word);
            }
            process.write("get on TreeMap: ");
            measureSearchTime(map, keysToSearch, 10);
        }
        try (reader = inputFile.Reader()) {
            value map = HashMap<String, Integer>(); 
            value keysToSearch = ArrayList<String>();
            while (exists word = reader.readLine()) { 
                map.put(word, word.size);
                keysToSearch.add(word);
            }
            process.write("get on HashMap: ");
            measureSearchTime(map, keysToSearch, 10);
        }
    }
    else {
        print("input file does not exist");
    }
    
}