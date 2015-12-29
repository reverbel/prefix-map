"Minimum length (in `Character`s) of a `KeyElement`, in the string 
 representation of a `TernaryTreeNode<KeyElement, Item>`."
variable Integer paddedElementSize = 1;

"Minimum length (in `Character`s) of an `Item`, in the  the string 
 representation of a `TernaryTreeNode<KeyElement, Item>`." 
variable Integer paddedItemSize = 6;

"A node of a ternary tree."
class TernaryTreeNode<KeyElement, Item>(element)
        given KeyElement satisfies Object {
    
    "The key element in this node."
    shared KeyElement element;
    
    "The optional item in this node. It must be present in a terminal 
     node and is (logically) absent in a non-terminal node."
    shared variable Item? item = null;
    
    "The parent node, which is `null` in the 
     case of the root of a ternary tree."
    shared variable TernaryTreeNode<KeyElement, Item>? parent = null;
    
    "The optional left child node."
    shared variable TernaryTreeNode<KeyElement, Item>? left = null;
    
    "The optional middle child node. A node with 
     no middle child must be terminal."
    shared variable TernaryTreeNode<KeyElement, Item>? middle = null;
    
    "The optional right child node."
    shared variable TernaryTreeNode<KeyElement, Item>? right = null;
    
    "True if this is a terminal node, false otherwise."
    shared variable Boolean terminal = false;
    
    "Returns a deep copy of this node."
    shared TernaryTreeNode<KeyElement, Item> deepCopy() {
        value copy = TernaryTreeNode<KeyElement, Item>(this.element);
        copy.item = this.item;
        if (exists l = left) {
            value leftCopy = l.deepCopy();
            leftCopy.parent = copy;
            copy.left = leftCopy;
        }
        if (exists m = middle) {
            value middleCopy = m.deepCopy();
            middleCopy.parent = copy;
            copy.middle = middleCopy;
        }
        if (exists r = right) {
            value rightCopy = r.deepCopy();
            rightCopy.parent = copy;
            copy.right = rightCopy;
        }
        copy.terminal = this.terminal;
        return copy;
    }
    
    "The size of the subtree rooted at this node."
    shared Integer size {
        variable Integer size = if (terminal) then 1 else 0;
        if (exists l = left) {
            size += l.size;
        }
        if (exists m = middle) {
            size += m.size;
        }
        if (exists r = right) {
            size += r.size;
        }
        return size;
    }
    
    "A string that identifies this node."
    String id =>
            "Node@``hash.string.padLeading(10, '_')``";
    
    "A developer-friendly string representation of this node."
    shared actual String string {
        value sBuilder = StringBuilder();
        sBuilder.append(id)
                .append(": ")
                .append(element.string.padLeading(paddedElementSize))
                .append(", ")
                .append(item?.string?.padLeading(paddedItemSize) else "<null>")
                .append(", ")
                .append(parent?.id else "      no parent")
                .append(", ")
                .append(left?.id else "  no left child")
                .append(", ")
                .append(middle?.id else "no middle child")
                .append(", ")
                .append(right?.id else " no right child");
        if (terminal) {
            sBuilder.append(", T");
        }
        return sBuilder.string;
    }
}
