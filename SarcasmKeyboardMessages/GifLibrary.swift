import Foundation

enum GifLibrary {
    static let all: [GifPhrase] = free + pro

    // Free tier — 10 phrases, first 10 bundled GIFs
    static let free: [GifPhrase] = [
        .init(id: "sure_jan",        displayText: "sUrE jAn",        isFree: true,  gifFilename: "sarcasm_01.gif"),
        .init(id: "oh_really",       displayText: "oH rEaLlY?",      isFree: true,  gifFilename: "sarcasm_02.gif"),
        .init(id: "wow_cool",        displayText: "wOw cOoL",        isFree: true,  gifFilename: "sarcasm_03.gif"),
        .init(id: "great",           displayText: "gReAt",           isFree: true,  gifFilename: "sarcasm_04.gif"),
        .init(id: "yeah_no",         displayText: "yEaH nO",         isFree: true,  gifFilename: "sarcasm_05.gif"),
        .init(id: "of_course",       displayText: "oF cOuRsE",       isFree: true,  gifFilename: "sarcasm_06.gif"),
        .init(id: "thanks_i_guess",  displayText: "tHaNkS i GuEsS",  isFree: true,  gifFilename: "sarcasm_07.gif"),
        .init(id: "fine",            displayText: "fInE",            isFree: true,  gifFilename: "sarcasm_08.gif"),
        .init(id: "ha",              displayText: "hA",              isFree: true,  gifFilename: "sarcasm_09.gif"),
        .init(id: "whatever",        displayText: "wHaTeVeR",        isFree: true,  gifFilename: "sarcasm_10.gif"),
    ]

    // Pro tier — 20 phrases, next 22 bundled GIFs (31 & 32 are spares)
    static let pro: [GifPhrase] = [
        .init(id: "brilliant",       displayText: "bRiLlIaNt",       isFree: false, gifFilename: "sarcasm_11.gif"),
        .init(id: "how_original",    displayText: "hOw OrIgInAl",    isFree: false, gifFilename: "sarcasm_12.gif"),
        .init(id: "tell_me_more",    displayText: "tElL mE mOrE",    isFree: false, gifFilename: "sarcasm_13.gif"),
        .init(id: "so_surprised",    displayText: "sO sUrPrIsEd",    isFree: false, gifFilename: "sarcasm_14.gif"),
        .init(id: "must_be_nice",    displayText: "mUsT bE nIcE",    isFree: false, gifFilename: "sarcasm_15.gif"),
        .init(id: "not_my_problem",  displayText: "nOt mY pRoBlEm",  isFree: false, gifFilename: "sarcasm_16.gif"),
        .init(id: "ok_boomer",       displayText: "oK bOoMeR",       isFree: false, gifFilename: "sarcasm_17.gif"),
        .init(id: "youre_welcome",   displayText: "yOu'Re wElCoMe",  isFree: false, gifFilename: "sarcasm_18.gif"),
        .init(id: "amazing",         displayText: "aMaZiNg",         isFree: false, gifFilename: "sarcasm_19.gif"),
        .init(id: "no_thanks",       displayText: "nO tHaNkS",       isFree: false, gifFilename: "sarcasm_20.gif"),
        .init(id: "so_what",         displayText: "sO wHaT",         isFree: false, gifFilename: "sarcasm_21.gif"),
        .init(id: "good_luck",       displayText: "gOoD lUcK",       isFree: false, gifFilename: "sarcasm_22.gif"),
        .init(id: "clearly",         displayText: "cLeArLy",         isFree: false, gifFilename: "sarcasm_23.gif"),
        .init(id: "mmm_hmm",         displayText: "mMm hMm",         isFree: false, gifFilename: "sarcasm_24.gif"),
        .init(id: "right",           displayText: "rIgHt",           isFree: false, gifFilename: "sarcasm_25.gif"),
        .init(id: "as_if",           displayText: "aS iF",           isFree: false, gifFilename: "sarcasm_26.gif"),
        .init(id: "duh",             displayText: "dUh",             isFree: false, gifFilename: "sarcasm_27.gif"),
        .init(id: "omg_stop",        displayText: "oMg sToP",        isFree: false, gifFilename: "sarcasm_28.gif"),
        .init(id: "interesting",     displayText: "iNtErEsTiNg",     isFree: false, gifFilename: "sarcasm_29.gif"),
        .init(id: "noted",           displayText: "nOtEd",           isFree: false, gifFilename: "sarcasm_30.gif"),
    ]
}
