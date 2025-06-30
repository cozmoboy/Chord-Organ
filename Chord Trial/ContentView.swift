import SwiftUI
import AVFoundation

class MIDIPlayer: ObservableObject {
    private var engine = AVAudioEngine()
    private var sampler = AVAudioUnitSampler()
    private var activeNotes: Set<UInt8> = []

    private let velocity: UInt8 = 100
    private let decayDuration: TimeInterval = 0.5
    private var bankURL: URL?

    init() {
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        try? engine.start()

        if let url = Bundle.main.url(forResource: "GeneralUser-GS", withExtension: "sf2") {
            self.bankURL = url
            setInstrument(program: 18)
        }
    }

    func setInstrument(program: UInt8) {
        guard let bankURL = bankURL else { return }
        try? sampler.loadSoundBankInstrument(
            at: bankURL,
            program: program,
            bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
            bankLSB: 0
        )
    }

    func playNote(note: UInt8) {
        if !activeNotes.contains(note) {
            sampler.startNote(note, withVelocity: velocity, onChannel: 0)
            activeNotes.insert(note)
        }
    }

    func stopNote(note: UInt8) {
        sampler.stopNote(note, onChannel: 0)
        activeNotes.remove(note)
    }

    func stopAllNotes() {
        for note in activeNotes {
            sampler.stopNote(note, onChannel: 0)
        }
        activeNotes.removeAll()
    }
}

struct ContentView: View {
    @StateObject private var midiPlayer = MIDIPlayer()
    @State private var selectedProgram: Int = 18
    @State private var showInstrumentPicker = false

    let chordTypes = ["", "7", "m", "aug", "dim"]
    let tonicOrder = ["Eb", "Bb", "F", "C", "G", "D", "A", "E", "B", "F#", "Db", "Ab"]
    /* let bassNotes: [String: UInt8] = [
        "Eb": 27, "Bb": 34, "F": 29, "C": 24, "G": 31, "D": 26, "A": 33, "E": 28,
        "B": 35, "F#": 30, "Db": 25, "Ab": 32
    ] */
    
    let bassNotes: [String: UInt8] = [
            "Eb": 39, "Bb": 46, "F": 41, "C": 36, "G": 43, "D": 38, "A": 45, "E": 40,
            "B": 47, "F#": 42, "Db": 37, "Ab": 44
        ]

    let chordDict: [String: [UInt8]] = [
        "C": [60, 64, 67], "C7": [60, 64, 67, 70], "Cm": [60, 63, 67], "Caug": [60, 64, 68], "Cdim": [60, 63, 66],
        "G": [67, 71, 74], "G7": [67, 71, 74, 77], "Gm": [67, 70, 74], "Gaug": [67, 71, 75], "Gdim": [67, 70, 73],
        "D": [62, 66, 69], "D7": [62, 66, 69, 72], "Dm": [62, 65, 69], "Daug": [62, 66, 70], "Ddim": [62, 65, 68],
        "A": [69, 73, 76], "A7": [69, 73, 76, 79], "Am": [69, 72, 76], "Aaug": [69, 73, 77], "Adim": [69, 72, 75],
        "E": [64, 68, 71], "E7": [64, 68, 71, 74], "Em": [64, 67, 71], "Eaug": [64, 68, 72], "Edim": [64, 67, 70],
        "B": [71, 75, 78], "B7": [71, 75, 78, 81], "Bm": [71, 74, 78], "Baug": [71, 75, 79], "Bdim": [71, 74, 77],
        "F": [65, 69, 72], "F7": [65, 69, 72, 75], "Fm": [65, 68, 72], "Faug": [65, 69, 73], "Fdim": [65, 68, 71],
        "Bb": [70, 74, 77], "Bb7": [70, 74, 77, 80], "Bbm": [70, 73, 77], "Bbaug": [70, 74, 78], "Bbdim": [70, 73, 76],
        "Eb": [63, 67, 70], "Eb7": [63, 67, 70, 73], "Ebm": [63, 66, 70], "Ebaug": [63, 67, 71], "Ebdim": [63, 66, 69],
        "Ab": [68, 72, 75], "Ab7": [68, 72, 75, 78], "Abm": [68, 71, 75], "Abaug": [68, 72, 76], "Abdim": [68, 71, 74],
        "Db": [61, 65, 68], "Db7": [61, 65, 68, 71], "Dbm": [61, 64, 68], "Dbaug": [61, 65, 69], "Dbdim": [61, 64, 67],
        "F#": [66, 70, 73], "F#7": [66, 70, 73, 76], "F#m": [66, 69, 73], "F#aug": [66, 70, 74], "F#dim": [66, 69, 72]
    ]

    let instrumentNames: [String] = [
        "Acoustic Grand Piano", "Bright Acoustic Piano", "Electric Grand Piano", "Honky-tonk Piano",
        "Electric Piano 1", "Electric Piano 2", "Harpsichord", "Clavinet",
        "Celesta", "Glockenspiel", "Music Box", "Vibraphone",
        "Marimba", "Xylophone", "Tubular Bells", "Dulcimer",
        "Drawbar Organ", "Percussive Organ", "Rock Organ", "Church Organ",
        "Reed Organ", "Accordion", "Harmonica", "Tango Accordion",
        "Acoustic Guitar (nylon)", "Acoustic Guitar (steel)", "Electric Guitar (jazz)", "Electric Guitar (clean)",
        "Electric Guitar (muted)", "Overdriven Guitar", "Distortion Guitar", "Guitar Harmonics",
        "Acoustic Bass", "Electric Bass (finger)", "Electric Bass (pick)", "Fretless Bass",
        "Slap Bass 1", "Slap Bass 2", "Synth Bass 1", "Synth Bass 2",
        "Violin", "Viola", "Cello", "Contrabass",
        "Tremolo Strings", "Pizzicato Strings", "Orchestral Harp", "Timpani",
        "String Ensemble 1", "String Ensemble 2", "Synth Strings 1", "Synth Strings 2",
        "Choir Aahs", "Voice Oohs", "Synth Voice", "Orchestra Hit",
        "Trumpet", "Trombone", "Tuba", "Muted Trumpet",
        "French Horn", "Brass Section", "Synth Brass 1", "Synth Brass 2",
        "Soprano Sax", "Alto Sax", "Tenor Sax", "Baritone Sax",
        "Oboe", "English Horn", "Bassoon", "Clarinet",
        "Piccolo", "Flute", "Recorder", "Pan Flute"
    ]

    var body: some View {
        GeometryReader { geo in
            let buttonWidth = geo.size.width / CGFloat(tonicOrder.count) * 0.9
            let buttonHeight = geo.size.height / (CGFloat(chordTypes.count) + 3.5)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: {
                        showInstrumentPicker.toggle()
                    }) {
                        Text("\(selectedProgram): \(instrumentNames[selectedProgram])")
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    .sheet(isPresented: $showInstrumentPicker) {
                        NavigationView {
                            List(instrumentNames.indices, id: \ .self) { i in
                                Button("\(i): \(instrumentNames[i])") {
                                    selectedProgram = i
                                    midiPlayer.setInstrument(program: UInt8(i))
                                    showInstrumentPicker = false
                                }
                            }
                            .navigationTitle("Select Instrument")
                            .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                }

                Spacer(minLength: 4)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: tonicOrder.count), spacing: 4) {
                    ForEach(chordTypes.reversed(), id: \ .self) { chordType in
                        ForEach(tonicOrder, id: \ .self) { tonic in
                            let label = tonic + chordType
                            chordButton(label: label, width: buttonWidth, height: buttonHeight)
                        }
                    }

                    // Empty row for spacing
                    ForEach(0..<tonicOrder.count) { _ in
                        Color.clear.frame(height: buttonHeight * 0.5)
                    }

                    // Bass note buttons
                    ForEach(tonicOrder, id: \ .self) { tonic in
                        bassButton(label: tonic, width: buttonWidth, height: buttonHeight)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom)
            }
            .onAppear {
                midiPlayer.setInstrument(program: UInt8(selectedProgram))
            }
        }
    }

    func chordButton(label: String, width: CGFloat, height: CGFloat) -> some View {
        Button(action: {}) {
            Text(label)
                .frame(width: width, height: height)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(6)
                .font(.system(size: 12))
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0)
                .onEnded { _ in
                    if let notes = chordDict[label] {
                        for note in notes {
                            midiPlayer.playNote(note: note)
                        }
                    }
                }
                .sequenced(before: DragGesture(minimumDistance: 0))
                .onEnded { _ in
                    if let notes = chordDict[label] {
                        for note in notes {
                            midiPlayer.stopNote(note: note)
                        }
                    }
                }
        )
    }

    func bassButton(label: String, width: CGFloat, height: CGFloat) -> some View {
        Button(action: {}) {
            Text(label)
                .frame(width: width, height: height)
                .background(Color.green)
                .foregroundColor(.black)
                .cornerRadius(6)
                .font(.system(size: 12))
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0)
                .onEnded { _ in
                    if let note = bassNotes[label] {
                        midiPlayer.playNote(note: note)
                    }
                }
                .sequenced(before: DragGesture(minimumDistance: 0))
                .onEnded { _ in
                    if let note = bassNotes[label] {
                        midiPlayer.stopNote(note: note)
                    }
                }
        )
    }
}

