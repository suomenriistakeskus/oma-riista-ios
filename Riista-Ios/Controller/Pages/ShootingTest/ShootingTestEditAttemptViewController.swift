import Foundation
import MaterialComponents.MaterialButtons
import RiistaCommon


class ShootingTestEditAttemptViewController : BaseViewController, UITextFieldDelegate, SelectSingleStringViewControllerDelegate {

    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var typeSelect: UISegmentedControl!
    @IBOutlet weak var hitsLabel: UILabel!
    @IBOutlet weak var hitSelect: UISegmentedControl!
    @IBOutlet weak var resultView: SelectStringView!
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var noteField: UITextField!
    @IBOutlet weak var buttonArea: UIView!
    @IBOutlet weak var cancelButton: MDCButton!
    @IBOutlet weak var saveButton: MDCButton!

    var participantId: Int64?
    var participantRev: Int32?
    var attemptId: Int64?

    var enableBear = true
    var enableMoose = true
    var enableRoeDeer = true
    var enableBow = true

    var shootingTestManager: ShootingTestManager?

    private lazy var editableAttemptData: ShootingTestAttemptData = ShootingTestAttemptData()

    private var keyboardHandler: KeyboardHandler?
    private let stringProvider = LocalizedStringProvider()
    private lazy var logger = AppLogger(for: self, printTimeStamps: false)

    override func viewDidLoad() {
        super.viewDidLoad()

        self.cancelButton.applyOutlinedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        self.saveButton.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())

        self.typeSelect.addTarget(self, action: #selector(typeControlValueChanged(sender:)), for:.valueChanged)
        self.hitSelect.addTarget(self, action: #selector(hitsControlValueChanged(sender:)), for:.valueChanged)

        noteField.inputAccessoryView = KeyboardToolBar().hideKeyboardOnDone(editView: noteField)
        self.noteField.delegate = self
        self.resultView.label.text = "ShootingTestAttemptListResultTitle".localized().uppercased()
        self.resultView.onClicked = {
            self.navigateToResultSelection()
        }

        // use same font for all labels
        let labelFont = UIFont.appFont(for: .label, fontWeight: .regular)
        self.typeLabel.font = labelFont
        self.hitsLabel.font = labelFont
        self.resultView.label.label.font = labelFont
        self.noteLabel.font = labelFont


        // No need to adjust content upwards/downwards when keyboard is opened / closed
        // -> also no need for delegate nor listening of keyboard events
        keyboardHandler = KeyboardHandler(view: view, contentMovement: .none)

        self.updateUiState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.typeLabel.text = "ShootingTestAttemptTypeTitle".localized().uppercased()
        self.typeSelect.setTitle("ShootingTestTypeBear".localized(),
                                 forSegmentAt: ShootingTestType.bear.segmentedControlIndex)
        self.typeSelect.setTitle("ShootingTestTypeMoose".localized(),
                                 forSegmentAt: ShootingTestType.moose.segmentedControlIndex)
        self.typeSelect.setTitle("ShootingTestTypeRoeDeer".localized(),
                                 forSegmentAt: ShootingTestType.roeDeer.segmentedControlIndex)
        self.typeSelect.setTitle("ShootingTestTypeBow".localized(),
                                 forSegmentAt: ShootingTestType.bow.segmentedControlIndex)

        self.hitsLabel.text = "ShootingTestAttemptHitsTitle".localized().uppercased()

        self.noteLabel.text = "ShootingTestAttemptNoteTitle".localized().uppercased()
        self.noteField.placeholder = "ShootingTestAttemptNoteHint".localized()

        self.cancelButton.setTitle("Cancel".localized(), for: .normal)
        self.saveButton.setTitle("Save".localized(), for: .normal)

        title = "ShootingTestAttemptEditViewTitle".localized()

        if (self.attemptId != nil && self.editableAttemptData.originalAttempt == nil) {
            // we've got an attempt id (i.e. we're editing) but we don't yet have original attempt
            self.refreshData()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        keyboardHandler?.hideKeyboard()
        super.viewWillDisappear(animated)
    }

    func refreshData() {
        guard let shootingTestManager = self.shootingTestManager,
              let attemptId = self.attemptId else {
            logger.w { "No shootingTestManager / attempt id, refusing to refresh" }
            return
        }

        shootingTestManager.getAttempt(attemptId: attemptId) { [weak self] attempt, error in
            guard let self = self else { return }

            if let attemptData = attempt?.toAttemptdData() {
                self.editableAttemptData = attemptData
                self.updateUiState()
            } else {
                self.logger.w { "getAttempt failed: \(error?.localizedDescription ?? String(describing: error))" }
            }
        }
    }

    @IBAction func cancelPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func savePressed(_ sender: UIButton) {
        // ensure editable data is up-to-date
        self.updateEditableAttemptData()

        guard let attemptData = self.editableAttemptData.getValidatedAttemptData() else {
            logger.v { "Failed to create valid attempt, not saving" }
            return
        }

        if let attemptId = self.attemptId, attemptId >= 0 {
            saveAndUpdateAttempt(attemptData: attemptData)
        } else {
            saveAndAddAttempt(attemptData: attemptData)
        }
    }

    private func saveAndAddAttempt(attemptData: ValidatedShootingTestAttemptData) {
        guard let shootingTestManager = self.shootingTestManager,
              let participantId = self.participantId,
              let participantRev = self.participantRev else {
            logger.w { "No shootingTestManager or participant id / rev, cannot save" }
            return
        }

        shootingTestManager.addAttemptForParticipant(
            participantId: participantId,
            particiopantRev: participantRev,
            shootingTestType: attemptData.shootingTestType,
            shootingTestResult: attemptData.shootingTestResult,
            hits: attemptData.hits,
            note: attemptData.note
        ) { [weak self] success, error in
            guard let self = self else { return }

            if (success) {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.logger.w {
                    "addAttemptForParticipant failed: \(error?.localizedDescription ?? String(describing: error))"
                }
            }
        }
    }

    private func saveAndUpdateAttempt(attemptData: ValidatedShootingTestAttemptData) {
        guard let shootingTestManager = self.shootingTestManager,
              let attemptId = attemptData.attemptId,
              let attemptRev = attemptData.attemptRev,
              let participantId = self.participantId,
              let participantRev = self.participantRev else {
            logger.w { "No attempt, participant id / rev -> cannot save" }
            return
        }

        shootingTestManager.updateAttempt(
            attemptId: attemptId,
            attemptRev: attemptRev,
            participantId: participantId,
            participantRev: participantRev,
            shootingTestType: attemptData.shootingTestType,
            shootingTestResult: attemptData.shootingTestResult,
            hits: attemptData.hits,
            note: attemptData.note
        ) { [weak self] success, error in
            guard let self = self else { return }

            if (success) {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.logger.d { "updateAttempt failed: \(error?.localizedDescription ?? String(describing: error))" }
            }
        }
    }

    @objc func typeControlValueChanged(sender: UISegmentedControl) {
        editableAttemptData.shootingTestType = ShootingTestType.fromIndex(sender.selectedSegmentIndex)
        editableAttemptData.hits = nil
        editableAttemptData.shootingTestResult = nil
        editableAttemptData.note = nil

        self.updateUiState()
    }

    @objc func hitsControlValueChanged(sender: UISegmentedControl) {
        editableAttemptData.hits = sender.numberOfHits
        editableAttemptData.updateShootingTestResult()
        editableAttemptData.note = nil

        self.updateUiState()
    }

    private func updateUiState() {
        self.updateShootingTestTypeInputState()
        self.updateHitsInputState()
        self.updateResultButtonState()
        self.updateNoteInputState()
        self.updateSaveButtonState()
    }

    private func updateShootingTestTypeInputState() {
        self.typeSelect.setEnabled(enableBear, forSegmentAt: ShootingTestType.bear.segmentedControlIndex);
        self.typeSelect.setEnabled(enableMoose, forSegmentAt: ShootingTestType.moose.segmentedControlIndex);
        self.typeSelect.setEnabled(enableRoeDeer, forSegmentAt: ShootingTestType.roeDeer.segmentedControlIndex);
        self.typeSelect.setEnabled(enableBow, forSegmentAt: ShootingTestType.bow.segmentedControlIndex);

        self.typeSelect.selectedSegmentIndex =
            editableAttemptData.shootingTestType?.segmentedControlIndex ?? UISegmentedControl.noSegment
    }

    private func updateHitsInputState() {
        let shootingTestTypeSelected = editableAttemptData.shootingTestType != nil
        let otherThanBowSelected = shootingTestTypeSelected && editableAttemptData.shootingTestType != .bow

        self.hitSelect.setEnabled(otherThanBowSelected, forSegmentAt: 0)
        self.hitSelect.setEnabled(shootingTestTypeSelected, forSegmentAt: 1)
        self.hitSelect.setEnabled(shootingTestTypeSelected, forSegmentAt: 2)
        self.hitSelect.setEnabled(shootingTestTypeSelected, forSegmentAt: 3)
        self.hitSelect.setEnabled(shootingTestTypeSelected, forSegmentAt: 4)

        self.hitSelect.numberOfHits = editableAttemptData.hits
    }

    private func updateResultButtonState() {
        self.resultView.isEnabled = editableAttemptData.shootingTestType != nil && editableAttemptData.hits != nil
        self.resultView.valueLabel.text = editableAttemptData.shootingTestResult?.localized(stringProvider: stringProvider)
    }

    private func updateNoteInputState() {
        let show = editableAttemptData.shootingTestResult == .rebated

        self.noteLabel.isHidden = !show
        self.noteField.isHidden = !show
        self.noteField.text = editableAttemptData.note
    }

    private func updateSaveButtonState() {
        self.saveButton.isEnabled = editableAttemptData.isValid()
    }

    private func updateEditableAttemptData() {
        // note value is not saved elsewhere. Other data should have already been updated
        editableAttemptData.note = self.noteField.text
    }


    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(_ scoreText: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }


    // MARK: Result selection

    func navigateToResultSelection() {
        let possibleResults = editableAttemptData.possibleResults
        if (possibleResults.isEmpty) {
            logger.w { "No possible results, refusing to initiate result change" }
            return
        }

        let viewcontroller = SelectSingleStringViewController()
        viewcontroller.title = "ShootingTestAttemptResultTitle".localized()
        viewcontroller.delegate = self
        viewcontroller.setValues(values: possibleResults.map { result in
            result.localized(stringProvider: stringProvider)
        })

        self.navigationController?.pushViewController(viewcontroller, animated: true)
    }


    // MARK: SelectSingleStringViewControllerDelegate

    func onStringSelected(string: SelectSingleStringViewController.SelectableString) {
        let possibleResults = editableAttemptData.possibleResults
        if (possibleResults.isEmpty) {
            logger.w { "No possible shooting test results, refusing to update result" }
            return
        }

        guard let shootingTestResult = possibleResults.getOrNil(index: Int(string.id)) else {
            logger.w { "No possible shooting test result for index \(string.id), not updating result" }
            return
        }

        editableAttemptData.shootingTestResult = shootingTestResult

        self.updateUiState()
    }
}


fileprivate class ShootingTestAttemptData {
    private lazy var logger = AppLogger(for: self, printTimeStamps: false)

    static let maxNumberOfHits: [ShootingTestType : Int] = [
        .bear : 4,
        .moose : 4,
        .roeDeer : 4,
        .bow : 3,
    ]

    let originalAttempt: CommonShootingTestAttempt?
    var shootingTestType: ShootingTestType? {
        didSet {
            updateIsQualified()
        }
    }
    var hits: Int? {
        didSet {
            updateIsQualified()
        }
    }
    var shootingTestResult: ShootingTestResult?
    var note: String?


    var possibleResults: [ShootingTestResult] {
        if let isQualified = self.isQualified {
            return [
                isQualified ? .qualified : .unqualified,
                .rebated,
                .timedOut
            ]
        } else {
            return []
        }
    }

    private var isQualified: Bool? // nil when information not yet available

    init(originalAttempt: CommonShootingTestAttempt? = nil,
         shootingTestType: ShootingTestType? = nil,
         hits: Int? = nil,
         shootingTestResult: ShootingTestResult? = nil,
         note: String? = nil) {
        self.originalAttempt = originalAttempt
        self.shootingTestType = shootingTestType
        self.hits = hits
        self.shootingTestResult = shootingTestResult
        self.note = note

        self.updateIsQualified()
    }

    func updateShootingTestResult() {
        if let isQualified = isQualified {
            shootingTestResult = isQualified ? .qualified : .unqualified
        } else {
            shootingTestResult = nil
        }
    }

    func getValidatedAttemptData() -> ValidatedShootingTestAttemptData? {
        guard let shootingTestType = self.shootingTestType else {
            logger.v { "Not valid: no shootingTestType"}
            return nil
        }
        guard let shootingTestResult = self.shootingTestResult else {
            logger.v { "Not valid: no shootingTestResult"}
            return nil
        }
        guard let maxNumberOfHitsForTestType = Self.maxNumberOfHits[shootingTestType] else {
            logger.e { "Not valid: no max number of hits for shootingTestType \(shootingTestType)"}
            return nil
        }
        guard let hits = self.hits else {
            logger.v { "Not valid: no hits"}
            return nil
        }

        if (hits < 0 || hits > maxNumberOfHitsForTestType) {
            logger.v { "Not valid: invalid hit count = \(hits) shootingTestType \(shootingTestType)"}
            return nil
        }

        return ValidatedShootingTestAttemptData(
            attemptId: originalAttempt?.id,
            attemptRev: originalAttempt?.rev,
            shootingTestType: shootingTestType,
            hits: hits,
            shootingTestResult: shootingTestResult,
            note: note
        )
    }

    func isValid() -> Bool {
        getValidatedAttemptData() != nil
    }

    private func updateIsQualified() {
        guard let shootingTestType = self.shootingTestType else {
            logger.v { "Refusing to update isQualified: no shooting test type" }
            self.isQualified = nil
            return
        }
        guard let maxNumberOfHitsForTestType = Self.maxNumberOfHits[shootingTestType] else {
            logger.e { "Refusing to update isQualified: no max number of hits for test type \(shootingTestType)" }
            self.isQualified = nil
            return
        }

        if let hits = self.hits {
            self.isQualified = hits >= maxNumberOfHitsForTestType
        } else {
            self.isQualified = nil
        }
    }
}

fileprivate struct ValidatedShootingTestAttemptData {
    var attemptId: Int64?
    var attemptRev: Int32?
    let shootingTestType: ShootingTestType
    let hits: Int
    let shootingTestResult: ShootingTestResult
    let note: String?
}


fileprivate extension CommonShootingTestAttempt {
    func toAttemptdData() -> ShootingTestAttemptData {
        ShootingTestAttemptData(
            originalAttempt: self,
            shootingTestType: self.type.value,
            hits: Int(self.hits),
            shootingTestResult: self.result.value,
            note: self.note
        )
    }
}


fileprivate extension ShootingTestType {
    private static let segmentedControlIndices: [ShootingTestType : Int] = [
        .bear : 0,
        .moose : 1,
        .roeDeer : 2,
        .bow : 3,
    ]

    var segmentedControlIndex: Int {
        return Self.segmentedControlIndices[self] ?? UISegmentedControl.noSegment
    }

    static func fromIndex(_ index: Int) -> ShootingTestType? {
        return Self.segmentedControlIndices.key(forValue: index)
    }
}


fileprivate extension UISegmentedControl {
    static let maxNumberOfHits = 4 // Keep in sync with storyboard and UISegmentedControl over there!

    var numberOfHits: Int? {
        get {
            if (self.selectedSegmentIndex == UISegmentedControl.noSegment) {
                 return nil
            } else if (self.selectedSegmentIndex < 0 || self.selectedSegmentIndex > Self.maxNumberOfHits) {
                return nil
            } else {
                return Self.maxNumberOfHits - self.selectedSegmentIndex
            }
        }
        set (hits) {
            if let hits = hits, hits >= 0, hits <= Self.maxNumberOfHits {
                self.selectedSegmentIndex = Self.maxNumberOfHits - hits
            } else {
                self.selectedSegmentIndex = UISegmentedControl.noSegment
            }
        }
    }
}
