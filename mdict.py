#! /usr/bin/env python
import sys
from bs4 import BeautifulSoup
import subprocess


class Mdict:
    def __init__(self, word):
        self.word = word
        p = subprocess.Popen(['bin/dicttool', '-e', word],
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE)
        out, err = p.communicate()
        self._soup = BeautifulSoup(out, "lxml")
        p_zh = subprocess.Popen(['bin/dicttool', '-z', word],
                                stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE)
        out_zh, err_zh = p_zh.communicate()
        self._soup_zh = BeautifulSoup(out_zh, "lxml")

    @property
    def IPAs(self):
        return [item.text.strip() for item in self._soup.find("span", "hg").findAll("span", {"d:pr": "US_IPA"})]

    @property
    def etym(self):
        res = self._soup.find("span", "etym")
        return(res.text if res else None)

    @property
    def derivatives(self):
        return [item.find("span", "l").text.strip() for item in self._soup.findAll("span", "subEntry")]

    @property
    def roots(self):
        return [item.text.strip() for item in self._soup.findAll("span", "ff")]

    @property
    def origin(self):
        return [item.text.strip() for item in self._soup.find("span", "etym").findAll("span", "la")]

    @property
    def definitions_zh(self):
        return [item.find("span", "trans").text.strip() for item in self._soup_zh.findAll("span", "trg")]


def printword(w):
    print(w.word)
    print("|{}|".format(','.join(w.IPAs)))

    for i, k in enumerate(w.definitions_zh):
        print(i+1, ".", k)
    print("\n{}\n".format(w.etym))

if __name__ == '__main__':
    word = sys.argv[1]
    q = Mdict(word)
    printword(q)