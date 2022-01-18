import Foundation


extension DiaryEntry {
    /**
     * Does this DiaryEntry have specimens for which there are newer versions available in the backend?
     *
     * The specimens are considered equal if they have the same remoteId.
     */
    @objc func shouldSpecimensBeUpdated(remoteEntry: DiaryEntry) -> Bool {
        return shouldSpecimensBeUpdated(remoteSpecimens: remoteEntry.specimens?.array)
    }

    @objc func shouldSpecimensBeUpdated(remoteSpecimens: Array<Any>?) -> Bool {
        let localSpecimenRevisions = DiaryEntry.getRemoteIdsAndRevs(specimens: self.specimens?.array)
        let remoteSpecimenRevisions = DiaryEntry.getRemoteIdsAndRevs(specimens: remoteSpecimens)

        for (remoteId, remoteRev) in remoteSpecimenRevisions {
            guard let localRev = localSpecimenRevisions[remoteId] else {
                // no local specimen -> should be updated
                return true
            }

            if (remoteRev > localRev) {
                return true
            }
        }

        return false
    }

    private class func getRemoteIdsAndRevs(specimens: Array<Any>?) -> Dictionary<Int, Int> {
        guard let specimens = specimens else { return [Int: Int]() }

        return specimens
            .compactMap({ $0 as? RiistaSpecimen })
            .reduce(into: [Int: Int]()) { (remoteIdsAndRevs, specimen) in
                if let remoteId = specimen.remoteId?.intValue, let rev = specimen.rev?.intValue {
                    remoteIdsAndRevs[remoteId] = rev
                }
            }
    }
}
