Config = {}

-- edited by me becuase this script was horrible with nothing working with what it was supposed to, was just a chat gpt script threw up.
Config.NPCModel = 's_m_m_doctor_01'

Config.ChargeMoney = true
Config.RemovalPrice = 250
Config.MoneyAccount = 'cash'

Config.Animation = {
    dict = 'mini@repair',
    anim = 'fixing_a_ped',
    duration = 3000
}

Config.Notifications = {
    success = 'Physical therapy completed successfully!',
    notEnoughMoney = 'You need $%s for physical therapy!',
    noCrutch = 'You do not have a crutch.',
    cancelled = 'Physical therapy cancelled.',
    notAtLocation = 'You must be at a medical facility for physical therapy!'
}

Config.RequireMedicLocation = false

Config.MedicLocations = {
    {
        name = 'Pillbox Medical Center',
        coords = vector4(296.268127, -591.969238, 43.265259, 73.700790),
        radius = 50.0,
        blip = {
            enabled = false,
            sprite = 61,
            color = 2,
            scale = 0.8,
            label = 'Medical Center'
        }
    },
}
