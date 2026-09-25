"""Move tone marks in open 'oa', 'oe', 'uy' syllables from the second vowel to the first (hoá→hóa, khoẻ→khỏe,
thuỷ→thủy) — the style Apple's Vietnamese localization uses. Syllables with a final consonant or glide (hoàn,
ngoài, huỳnh) and 'qu' + y (quỷ, quý) are the same in both styles and are left alone."""
import re, sys, pathlib, unicodedata, collections

A = dict(zip('àáảãạ', 'òóỏõọ')); A.update({k.upper(): v.upper() for k, v in A.items()})
E = dict(zip('èéẻẽẹ', 'òóỏõọ')); E.update({k.upper(): v.upper() for k, v in E.items()})
Y = dict(zip('ỳýỷỹỵ', 'ùúủũụ')); Y.update({k.upper(): v.upper() for k, v in Y.items()})
LETTER = r'[A-Za-zÀ-ỹ]'
OA = re.compile(r'([oO])([àáảãạÀÁẢÃẠèéẻẽẹÈÉẺẼẸ])(?!' + LETTER + ')')
UY = re.compile(r'(?<![qQ])([uU])([ỳýỷỹỵỲÝỶỸỴ])(?!' + LETTER + ')')

def tone_of(first, second):
    table = A if second in A else E if second in E else Y
    toned = table[second]
    toned = toned.upper() if first.isupper() else toned
    base = {'a': 'a', 'e': 'e', 'y': 'y'}[unicodedata.normalize('NFD', second)[0].lower()]
    return toned + (base.upper() if second.isupper() else base)

def convert(text):
    text = OA.sub(lambda m: tone_of(m.group(1), m.group(2)), text)
    return UY.sub(lambda m: tone_of(m.group(1), m.group(2)), text)

if __name__ == '__main__':
    write = '--write' in sys.argv
    paths = [pathlib.Path(p) for p in sys.argv[1:] if not p.startswith('--')]
    words = collections.Counter(); files_changed = 0
    for p in paths:
        s = p.read_text(encoding='utf-8')
        if s != unicodedata.normalize('NFC', s):
            print('WARNING not NFC:', p)
        new = convert(s)
        if new != s:
            files_changed += 1
            for a, b in zip(re.findall(r'\S+', s), re.findall(r'\S+', new)):
                if a != b: words[f'{a} → {b}'] += 1
            if write: p.write_text(new, encoding='utf-8')
    print(('WROTE' if write else 'DRY RUN'), files_changed, 'files,', sum(words.values()), 'words')
    for w, n in words.most_common(): print(f'{n:5d}  {w}')
