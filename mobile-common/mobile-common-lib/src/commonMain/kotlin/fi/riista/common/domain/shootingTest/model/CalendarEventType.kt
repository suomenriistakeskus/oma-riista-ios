package fi.riista.common.domain.shootingTest.model

import fi.riista.common.model.RepresentsBackendEnum

enum class CalendarEventType(
    override val rawBackendEnumValue: String,
): RepresentsBackendEnum {
    AMPUMAKOE("AMPUMAKOE"),
    JOUSIAMPUMAKOE("JOUSIAMPUMAKOE"),
    METSASTAJAKURSSI("METSASTAJAKURSSI"),
    METSASTAJATUTKINTO("METSASTAJATUTKINTO"),
    KOULUTUSTILAISUUS("KOULUTUSTILAISUUS"),
    VUOSIKOKOUS("VUOSIKOKOUS"),
    YLIMAARAINEN_KOKOUS("YLIMAARAINEN_KOKOUS"),
    NUORISOTAPAHTUMA("NUORISOTAPAHTUMA"),
    AMPUMAKILPAILU("AMPUMAKILPAILU"),
    RIISTAPOLKUKILPAILU("RIISTAPOLKUKILPAILU"),
    ERATAPAHTUMA("ERATAPAHTUMA"),
    HARJOITUSAMMUNTA("HARJOITUSAMMUNTA"),
    METSASTYKSENJOHTAJA_HIRVIELAIMET("METSASTYKSENJOHTAJA_HIRVIELAIMET"),
    METSASTYKSENJOHTAJA_SUURPEDOT("METSASTYKSENJOHTAJA_SUURPEDOT"),
    METSASTAJAKOULUTUS_HIRVIELAIMET("METSASTAJAKOULUTUS_HIRVIELAIMET"),
    METSASTAJAKOULUTUS_SUURPEDOT("METSASTAJAKOULUTUS_SUURPEDOT"),
    SRVAKOULUTUS("SRVAKOULUTUS"),
    PETOYHDYSHENKILO_KOULUTUS("PETOYHDYSHENKILO_KOULUTUS"),
    VAHINKOKOULUTUS("VAHINKOKOULUTUS"),
    TILAISUUS_KOULUILLE("TILAISUUS_KOULUILLE"),
    OPPILAITOSTILAISUUS("OPPILAITOSTILAISUUS"),
    NUORISOTILAISUUS("NUORISOTILAISUUS"),
    AMPUMAKOKEENVASTAANOTTAJA_KOULUTUS("AMPUMAKOKEENVASTAANOTTAJA_KOULUTUS"),
    METSASTAJATUTKINNONVASTAANOTTAJA_KOULUTUS("METSASTAJATUTKINNONVASTAANOTTAJA_KOULUTUS"),
    RIISTAVAHINKOTARKASTAJA_KOULUTUS("RIISTAVAHINKOTARKASTAJA_KOULUTUS"),
    METSASTYKSENVALVOJA_KOULUTUS("METSASTYKSENVALVOJA_KOULUTUS"),
    PIENPETOJEN_PYYNTI_KOULUTUS("PIENPETOJEN_PYYNTI_KOULUTUS"),
    RIISTALASKENTA_KOULUTUS("RIISTALASKENTA_KOULUTUS"),
    RIISTAKANTOJEN_HOITO_KOULUTUS("RIISTAKANTOJEN_HOITO_KOULUTUS"),
    RIISTAN_ELINYMPARISTON_HOITO_KOULUTUS("RIISTAN_ELINYMPARISTON_HOITO_KOULUTUS"),
    MUU_RIISTANHOITOKOULUTUS("MUU_RIISTANHOITOKOULUTUS"),
    AMPUMAKOULUTUS("AMPUMAKOULUTUS"),
    JALJESTAJAKOULUTUS("JALJESTAJAKOULUTUS"),
    MUU_TAPAHTUMA("MUU_TAPAHTUMA"),
    RHY_HALLITUKSEN_KOKOUS("RHY_HALLITUKSEN_KOKOUS"),
    HIRVIELAINTEN_VEROTUSSUUNNITTELU("HIRVIELAINTEN_VEROTUSSUUNNITTELU"),
    ;
}
