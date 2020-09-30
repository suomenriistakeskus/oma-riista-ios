import Foundation

class ShootingTestEditAttemptViewController : UIViewController, UITextFieldDelegate, ShootingTestValueButtonDelegate, ValueSelectionDelegate {
    private struct ClassConstants {
        static let BEAR_INDEX = 0
        static let MOOSE_INDEX = 1
        static let DEER_INDEX = 2
        static let BOW_INDEX = 3
    }

    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var typeSelect: UISegmentedControl!
    @IBOutlet weak var hitsLabel: UILabel!
    @IBOutlet weak var hitSelect: UISegmentedControl!
    @IBOutlet weak var resultTitle: UILabel!
    @IBOutlet weak var resultView: ShootingTestValueButton!
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var noteField: UITextField!
    @IBOutlet weak var buttonArea: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!

    @IBAction func cancelPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func savePressed(_ sender: UIButton) {
        let input = self.storeInputs()

        if (input.validateData()) {
            if (self.attemptId != nil && self.attemptId! >= 0) {
                self.saveAndUpdateAttempt(input: input)
            }
            else {
                self.saveAndAddAttempt(input: input)
            }
        }
    }

    var participantId: Int = -1
    var participantRev: Int = -1
    var attemptId: Int?
    var attempt: ShootingTestAttemptDetailed?

    var enableBear = true
    var enableMoose = true
    var enableRoeDeer = true
    var enableBow = true

    override func viewDidLoad() {
        super.viewDidLoad()

        Styles.styleNegativeButton(self.cancelButton)
        Styles.styleButton(self.saveButton)

        self.typeSelect.addTarget(self, action: #selector(typeControlValueChanged(sender:)), for:.valueChanged)
        self.hitSelect.addTarget(self, action: #selector(hitsControlValueChanged(sender:)), for:.valueChanged)

        self.noteField.delegate = self
        self.resultView.delegate = self

        self.hideKeyboard()
        self.resetUiValues()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.typeLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestAttemptTypeTitle").uppercased()
        self.typeSelect.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeBear"), forSegmentAt: 0)
        self.typeSelect.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeMoose"), forSegmentAt: 1)
        self.typeSelect.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeRoeDeer"), forSegmentAt: 2)
        self.typeSelect.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeBow"), forSegmentAt: 3)

        self.hitsLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestAttemptHitsTitle").uppercased()

        self.resultTitle.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestAttemptResultTitle").uppercased()

        self.noteLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestAttemptNoteTitle").uppercased()
        self.noteField.placeholder = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestAttemptNoteHint")

        self.cancelButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "Cancel"), for: .normal)
        self.saveButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "Save"), for: .normal)

        self.updateTitle()
        self.updateUiState()

        if (self.attempt == nil && self.attemptId != nil) {
            self.refreshData()
        }
    }

    func updateTitle() {
        let navController = self.navigationController as? RiistaNavigationController
        navController?.changeTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestAttemptEditViewTitle"))
    }

    func refreshData() {
        ShootingTestManager.getAttempt(attemptId: self.attemptId!)  { (result:Any?, error:Error?) in
            if (error == nil) {
                do {
                    let json = try JSONSerialization.data(withJSONObject: result!)
                    let attempt = try JSONDecoder().decode(ShootingTestAttemptDetailed.self, from: json)

                    self.attempt = attempt
                    self.refreshUiWith(attempt: self.attempt!)
                }
                catch {
                    print("Failed to parse <ShootingTestParticipantDetailed> item")
                }
            }
            else {
                print("getAttempt failed: " + (error?.localizedDescription)!)
            }
        }
    }

    private func resetUiValues() {
        self.typeSelect.selectedSegmentIndex = UISegmentedControl.noSegment
        self.hitSelect.selectedSegmentIndex = UISegmentedControl.noSegment

        self.resultView.setTitle(text: nil)

        self.noteField.text = nil
    }

    private func refreshUiWith(attempt: ShootingTestAttemptDetailed) {
        resetUiValues()

        switch attempt.type! {
        case ShootingTestAttemptDetailed.ClassConstants.TYPE_BEAR:
            self.typeSelect.selectedSegmentIndex = ClassConstants.BEAR_INDEX
            break
        case ShootingTestAttemptDetailed.ClassConstants.TYPE_MOOSE:
            self.typeSelect.selectedSegmentIndex = ClassConstants.MOOSE_INDEX
            break
        case ShootingTestAttemptDetailed.ClassConstants.TYPE_ROE_DEER:
            self.typeSelect.selectedSegmentIndex = ClassConstants.DEER_INDEX
            break
        case ShootingTestAttemptDetailed.ClassConstants.TYPE_BOW:
            self.typeSelect.selectedSegmentIndex = ClassConstants.BOW_INDEX
            break
        default:
            self.typeSelect.selectedSegmentIndex = UISegmentedControl.noSegment
            break
        }

        switch attempt.hits! {
        case 0:
            self.hitSelect.selectedSegmentIndex = 4
            break
        case 1:
            self.hitSelect.selectedSegmentIndex = 3
            break
        case 2:
            self.hitSelect.selectedSegmentIndex = 2
            break
        case 3:
            self.hitSelect.selectedSegmentIndex = 1
            break
        case 4:
            self.hitSelect.selectedSegmentIndex = 0
            break
        default:
            self.hitSelect.selectedSegmentIndex = UISegmentedControl.noSegment
            break
        }

        self.resultView.setTitle(text: ShootingTestAttemptDetailed.localizedResultText(value: attempt.result!))
        self.noteField.text = attempt.note

        self.updateUiState()
    }

    private func storeInputs() -> ShootingTestAttemptDetailed {
        var typeValue: String?
        var hitsValue: Int?
        var resultValue: String?
        var noteValue: String?

        switch self.typeSelect.selectedSegmentIndex {
        case ClassConstants.BEAR_INDEX:
            typeValue = ShootingTestAttemptDetailed.ClassConstants.TYPE_BEAR
            break
        case ClassConstants.MOOSE_INDEX:
            typeValue = ShootingTestAttemptDetailed.ClassConstants.TYPE_MOOSE
            break
        case ClassConstants.DEER_INDEX:
            typeValue = ShootingTestAttemptDetailed.ClassConstants.TYPE_ROE_DEER
            break
        case ClassConstants.BOW_INDEX:
            typeValue = ShootingTestAttemptDetailed.ClassConstants.TYPE_BOW
            break
        default:
            typeValue = nil
            break
        }

        switch self.hitSelect.selectedSegmentIndex {
        case 0:
            hitsValue = 4
            break
        case 1:
            hitsValue = 3
            break
        case 2:
            hitsValue = 2
            break
        case 3:
            hitsValue = 1
            break
        case 4:
            hitsValue = 0
            break
        default:
            hitsValue = nil
            break
        }

        resultValue = ShootingTestAttemptDetailed.textToResultValue(text: self.resultView.getTitle())
        noteValue = self.noteField.text
        if (noteValue != nil && noteValue!.isEmpty) {
            noteValue = nil
        }

        return ShootingTestAttemptDetailed(type: typeValue, hits: hitsValue, result: resultValue, note: noteValue)
    }

    private func isQualifiedResult() -> Bool {
        if (self.typeSelect.selectedSegmentIndex != ClassConstants.BOW_INDEX && self.hitSelect.selectedSegmentIndex == 0) {
            return true
        }
        else if (self.typeSelect.selectedSegmentIndex == ClassConstants.BOW_INDEX && self.hitSelect.selectedSegmentIndex == 1) {
            return true
        }

        return false
    }

    private func saveAndAddAttempt(input: ShootingTestAttemptDetailed) {
        ShootingTestManager.addAttemptForParticipant(participantId: self.participantId,
                                                     particiopantRev: self.participantRev,
                                                     type: input.type!,
                                                     result: input.result!,
                                                     hits: input.hits!,
                                                     note: input.note)
        { (result:Any?, error:Error?) in
            if (error == nil) {
                self.navigationController?.popViewController(animated: true)
            }
            else {
                print("addAttemptForParticipant failed: " + (error?.localizedDescription)!)
            }
        }
    }

    private func saveAndUpdateAttempt(input: ShootingTestAttemptDetailed) {
        ShootingTestManager.updateAttempt(attemptId: (self.attempt?.id)!,
                                          rev: (self.attempt?.rev)!,
                                          participantId: self.participantId,
                                          participantRev: self.participantRev,
                                          type: input.type!,
                                          result: input.result!,
                                          hits: input.hits!,
                                          note: input.note)
        { (result:Any?, error:Error?) in
            if (error == nil) {
                self.navigationController?.popViewController(animated: true)
            }
            else {
                print("updateAttempt failed: " + (error?.localizedDescription)!)
            }
        }
    }

    @objc func typeControlValueChanged(sender: UISegmentedControl) {
        self.hitSelect.selectedSegmentIndex = UISegmentedControl.noSegment
        self.resultView.setTitle(text: nil)
        self.noteField.text = nil

        self.updateUiState()
    }

    @objc func hitsControlValueChanged(sender: UISegmentedControl) {
        if (self.isQualifiedResult()) {
            self.resultView.setTitle(text: ShootingTestAttemptDetailed.localizedResultText(value: ShootingTestAttemptDetailed.ClassConstants.RESULT_QUALIFIED))
        }
        else {
            self.resultView.setTitle(text: ShootingTestAttemptDetailed.localizedResultText(value: ShootingTestAttemptDetailed.ClassConstants.RESULT_UNQUALIFIED))
        }
        self.noteField.text = nil

        self.updateUiState()
    }

    private func updateUiState() {
        let input = self.storeInputs()

        self.updateTypeInputState(input: input)
        self.updateHitsInputState(input: input)
        self.updateResultButtonState(input: input)
        self.updateNoteInputState(input: input)
        self.updateSaveButtonState(input: input)
    }

    private func updateTypeInputState(input: ShootingTestAttemptDetailed) {
        self.typeSelect.setEnabled(enableBear, forSegmentAt: ClassConstants.BEAR_INDEX);
        self.typeSelect.setEnabled(enableMoose, forSegmentAt: ClassConstants.MOOSE_INDEX);
        self.typeSelect.setEnabled(enableRoeDeer, forSegmentAt: ClassConstants.DEER_INDEX);
        self.typeSelect.setEnabled(enableBow, forSegmentAt: ClassConstants.BOW_INDEX);
    }

    private func updateHitsInputState(input: ShootingTestAttemptDetailed) {
        self.hitSelect.setEnabled(input.type != nil && ShootingTestAttemptDetailed.ClassConstants.TYPE_BOW != input.type, forSegmentAt: 0)
        self.hitSelect.setEnabled(input.type != nil, forSegmentAt: 1)
        self.hitSelect.setEnabled(input.type != nil, forSegmentAt: 2)
        self.hitSelect.setEnabled(input.type != nil, forSegmentAt: 3)
        self.hitSelect.setEnabled(input.type != nil, forSegmentAt: 4)
    }

    private func updateResultButtonState(input: ShootingTestAttemptDetailed) {
        self.resultView.setIsEnabled(enabled: input.type != nil && input.hits != nil)
    }

    private func updateNoteInputState(input: ShootingTestAttemptDetailed) {
        let show = ShootingTestAttemptDetailed.ClassConstants.RESULT_REBATED == input.result

        self.noteLabel.isHidden = !show
        self.noteField.isHidden = !show
    }

    private func updateSaveButtonState(input: ShootingTestAttemptDetailed) {
        self.saveButton.isEnabled = input.validateData()
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(_ scoreText: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }

    // MARK: ShootingTestValueButtonDelegate

    func didPressButton(_ tag: Int) {
        let sb = UIStoryboard.init(name: "DetailsStoryboard", bundle: nil)
        let controller = sb.instantiateViewController(withIdentifier: "valueListController") as! ValueListViewController
        controller.delegate = self
        controller.fieldKey = "RESULT"
        controller.titlePrompt = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestAttemptResultTitle")

        let valueList = [ShootingTestAttemptDetailed.localizedResultText(value: self.isQualifiedResult() ? ShootingTestAttemptDetailed.ClassConstants.RESULT_QUALIFIED : ShootingTestAttemptDetailed.ClassConstants.RESULT_UNQUALIFIED),
                         ShootingTestAttemptDetailed.localizedResultText(value: ShootingTestAttemptDetailed.ClassConstants.RESULT_REBATED),
                         ShootingTestAttemptDetailed.localizedResultText(value: ShootingTestAttemptDetailed.ClassConstants.RESULT_TIMED_OUT)]

        controller.values = valueList

        let segue = UIStoryboardSegue.init(identifier: "", source: self, destination: controller, performHandler: {
            self.navigationController?.pushViewController(controller, animated: true)
        })
        segue.perform()
    }

    // MARK: ValueSelectionDelegate

    func valueSelected(forKey key: String!, value: String!) {
        self.resultView.setTitle(text: value)

        self.updateUiState()
    }
}
