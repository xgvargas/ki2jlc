Papa = require 'papaparse'
fs = require 'fs'
argv = require('minimist')(process.argv[2...])

# console.log argv

config = {
    skipEmptyLines: yes
    transform: (val, col) -> val.trimLeft().trimRight()
}

try
    bomK = Papa.parse(fs.readFileSync(argv.b).toString(), config).data if argv.b
    posK = Papa.parse(fs.readFileSync(argv.p).toString(), config).data if argv.p
catch e
    console.log e.message
    # console.log e
    process.exit(1)

unless bomK or posK
    console.log '\nOops! No input files...'
    process.exit(1)


findColumn = (csv, name) -> csv[0].findIndex (el) -> el.toLowerCase() == name.toLowerCase()


stuffed = []


if bomK
    ref = findColumn bomK, 'Reference'
    val = findColumn bomK, 'Value'
    fp = findColumn bomK, 'Footprint'
    lcsc = findColumn bomK, 'LCSC'
    mouser = findColumn bomK, 'MOUSER'

    # console.log bomK[0]
    # console.log ref, val, fp, lcsc, mouser

    if lcsc <= 0
        console.log '\nCan\'t find the LCSC SKU code column...'
        process.exit(1)

    bomJ = [['comment','designator','footprint','LCSC']]
    mouserCnt = 0

    for item in bomK[1...]
        mouserCnt++ if item[mouser]
        if item[lcsc]
            stuffed.push item[ref]
            bomJ.push [item[val], item[ref], item[fp], item[lcsc]]

    if bomJ.length == 1
        console.log '\nNo part with a SKU was defined'
        process.exit(1)

    # console.log bomJ

    nfn = argv.b.replace /(.*)+\.csv$/, '$1-JLC.csv'
    fs.writeFileSync nfn, Papa.unparse(bomJ), 'utf-8'

    console.log """
        \nProcessed BOM with #{bomK.length-1} parts, being #{bomJ.length-1} LCSC and #{mouserCnt} Mouser
        Saved to: #{nfn}
        """


fixRules = {
    'C_0402_1005Metric': 0
    'C_0603_1608Metric': 0
    'CP_Elec_6.3x7.7': 0
    'CP_Elec_8x10': 0
    'D_SOD-123': 0
    'D_SOD-123F': 0
    'L_12x12mm_H6mm': 0
    'LQFP-100_14x14mm_P0.5mm': 0
    'QFN-32_EP_5x5_Pitch0.5mm': 0
    'R_0402_1005Metric': 0
    'R_0603_1608Metric': 0
    'R_0805_2012Metric': 0
    'R_Array_Concave_4x0603': 0
    'SC-89': 0
    # 'SOIC-8_3.9x4.9mm_P1.27mm': 0
    'SOT-23': 0
    'SOT-23-5': 0
    'SOT-363_SC-70-6': 0
    'TSSOP-16_4.4x5mm_P0.65mm': 0
    'SOIC': 90
}


if posK
    ref = findColumn posK, 'Ref'
    posx = findColumn posK, 'PosX'
    posy = findColumn posK, 'PosY'
    rot = findColumn posK, 'Rot'
    side = findColumn posK, 'Side'
    fp = findColumn posK, 'Package'
    # console.log posK[0]
    # console.log ref, posx, posy, rot, side

    posJ = [['designator','mid X','mid Y','layer','rotation']]

    top = 0
    topJ = 0
    bottom = 0
    bottomJ = 0

    for item in posK[1...]
        if item[side].toLowerCase() == 'top' then top++ else bottom++
        if !stuffed.length or (item[ref] in stuffed)
            if item[side].toLowerCase() == 'top' then topJ++ else bottomJ++

            angle = +item[rot]

            for k, fix of fixRules
                if item[fp].startsWith k
                    angle += fix
                    break

            posJ.push [item[ref], item[posx], item[posy], item[side], (angle % 360)]

    if posJ.length == 1
        console.log '\nNo part to be populated...'
        process.exit(1)

    # console.log posJ
    nfn = argv.p.replace /(.*)+\.csv$/, '$1-JLC.csv'

    fs.writeFileSync nfn, Papa.unparse(posJ), 'utf-8'

    console.log """
        \nProcessed POS file with #{top}/#{bottom} (top/bottom) parts, being #{topJ}/#{bottomJ} to be stuffed
        Saved to: #{nfn}
        """
