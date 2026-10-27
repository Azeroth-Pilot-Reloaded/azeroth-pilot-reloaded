-- Autonomous library wording; quest names/objectives still come from the client.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("unlock_locales", 5) then return end
local translations = {
    enUS = { "Accept %s", "Turn in %s", "Complete %s", "Verified unlock guidance is incomplete.", "Interact: %s" },
    frFR = { "Accepte %s", "Rends %s", "Accomplis %s", "Le parcours de déblocage vérifié est incomplet.", "Interagis : %s" },
    deDE = { "Nimm %s an", "Gib %s ab", "Schließe %s ab", "Die bestätigte Freischaltanleitung ist unvollständig.", "Interagiere: %s" },
    esES = { "Acepta %s", "Entrega %s", "Completa %s", "La guía de desbloqueo verificada está incompleta.", "Interactúa: %s" },
    esMX = { "Acepta %s", "Entrega %s", "Completa %s", "La guía de desbloqueo verificada está incompleta.", "Interactúa: %s" },
    itIT = { "Accetta %s", "Consegna %s", "Completa %s", "La guida verificata per lo sblocco è incompleta.", "Interagisci: %s" },
    koKR = { "%s 수락", "%s 반납", "%s 완료", "확인된 잠금 해제 경로가 불완전합니다.", "상호작용: %s" },
    ptBR = { "Aceite %s", "Entregue %s", "Conclua %s", "O guia de desbloqueio verificado está incompleto.", "Interaja: %s" },
    ruRU = { "Примите задание %s", "Сдайте задание %s", "Выполните %s", "Проверенный маршрут открытия доступа неполон.", "Взаимодействуйте: %s" },
    zhCN = { "接受%s", "交付%s", "完成%s", "已核实的解锁路线不完整。", "互动：%s" },
    zhTW = { "接受%s", "交付%s", "完成%s", "已核實的解鎖路線不完整。", "互動：%s" },
}
for locale, values in pairs(translations) do
    local catalog = assert(Lib.locales[locale])
    for index, kind in ipairs({ "accept", "turnin", "objective", "missing", "interact" }) do
        catalog["NAVIGATION_UNLOCK_" .. kind] = values[index]
    end
    catalog.NAVIGATION_UNLOCK_waypoint = catalog.RUN_WAYPOINT
end

local trackerWait = {
    enUS = "Waiting for the game to confirm access after %s.",
    frFR = "En attente de la confirmation d'accès par le jeu après %s.",
    deDE = "Warte auf die Zugangsbestätigung des Spiels nach %s.",
    esES = "Esperando que el juego confirme el acceso tras %s.",
    esMX = "Esperando que el juego confirme el acceso tras %s.",
    itIT = "In attesa che il gioco confermi l’accesso dopo %s.",
    koKR = "%s 이후 게임의 접근 권한 확인을 기다리는 중입니다.",
    ptBR = "Aguardando o jogo confirmar o acesso após %s.",
    ruRU = "Ожидание подтверждения доступа игрой после %s.",
    zhCN = "等待游戏在%s后确认访问权限。",
    zhTW = "等待遊戲在%s後確認存取權限。",
}
for locale, wording in pairs(trackerWait) do
    local catalog = Lib.locales[locale]
    catalog.NAVIGATION_UNLOCK_tracker_wait = wording
    catalog.NAVIGATION_UNLOCK_scenario = catalog.NAVIGATION_UNLOCK_objective
    catalog.NAVIGATION_UNLOCK_transport = catalog.NAVIGATION_UNLOCK_interact
    catalog.NAVIGATION_UNLOCK_action = catalog.NAVIGATION_UNLOCK_interact
    catalog.NAVIGATION_UNLOCK_npc_activity = catalog.NAVIGATION_UNLOCK_interact
end

local requirements = {
    enUS = { "Required currency: %s", "Required reputation: %s", "Required items: %s", "Learn spell %s", "Required skill: %s" },
    frFR = { "Monnaie requise : %s", "Réputation requise : %s", "Objets requis : %s", "Apprends le sort %s", "Compétence requise : %s" },
    deDE = { "Benötigte Währung: %s", "Benötigter Ruf: %s", "Benötigte Gegenstände: %s", "Erlerne Zauber %s", "Benötigte Fertigkeit: %s" },
    esES = { "Moneda necesaria: %s", "Reputación necesaria: %s", "Objetos necesarios: %s", "Aprende el hechizo %s", "Habilidad necesaria: %s" },
    esMX = { "Moneda necesaria: %s", "Reputación necesaria: %s", "Objetos necesarios: %s", "Aprende el hechizo %s", "Habilidad necesaria: %s" },
    itIT = { "Valuta richiesta: %s", "Reputazione richiesta: %s", "Oggetti richiesti: %s", "Impara l’incantesimo %s", "Competenza richiesta: %s" },
    koKR = { "필요 화폐: %s", "필요 평판: %s", "필요 아이템: %s", "%s 주문 배우기", "필요 기술: %s" },
    ptBR = { "Moeda necessária: %s", "Reputação necessária: %s", "Itens necessários: %s", "Aprenda o feitiço %s", "Perícia necessária: %s" },
    ruRU = { "Требуемая валюта: %s", "Требуемая репутация: %s", "Требуемые предметы: %s", "Изучите заклинание %s", "Требуемый навык: %s" },
    zhCN = { "所需货币：%s", "所需声望：%s", "所需物品：%s", "学习法术%s", "所需技能：%s" },
    zhTW = { "所需貨幣：%s", "所需聲望：%s", "所需物品：%s", "學習法術%s", "所需技能：%s" },
}
for locale, values in pairs(requirements) do
    for index, kind in ipairs({ "currency", "reputation", "item", "spellKnown", "skill" }) do
        Lib.locales[locale]["NAVIGATION_REQUIRES_" .. kind] = values[index]
    end
    Lib.locales[locale].NAVIGATION_REQUIRES_spell = values[4]
end

local timing = {
    enUS = { "Available after: %s", "Chromie Time required: %s", "Required Chromie Time campaign: %s" },
    frFR = { "Disponible après : %s", "Voyages dans le temps de Chromie requis : %s", "Campagne de Chromie requise : %s" },
    deDE = { "Verfügbar ab: %s", "Chromies Zeit erforderlich: %s", "Benötigte Zeitwanderungskampagne: %s" },
    esES = { "Disponible después de: %s", "Tiempo de Cromi requerido: %s", "Campaña de Cromi necesaria: %s" },
    esMX = { "Disponible después de: %s", "Tiempo de Cromi requerido: %s", "Campaña de Cromi necesaria: %s" },
    itIT = { "Disponibile dopo: %s", "Tempo di Cromie richiesto: %s", "Campagna di Cromie richiesta: %s" },
    koKR = { "이후 이용 가능: %s", "크로미의 시간 필요: %s", "필요한 크로미의 시간 대장정: %s" },
    ptBR = { "Disponível após: %s", "Tempo da Crona necessário: %s", "Campanha da Crona necessária: %s" },
    ruRU = { "Доступно после: %s", "Требуется время Хроми: %s", "Требуемая кампания Хроми: %s" },
    zhCN = { "开放时间：%s", "需要克罗米时间：%s", "所需克罗米时间战役：%s" },
    zhTW = { "開放時間：%s", "需要克羅米時間：%s", "所需克羅米時間戰役：%s" },
}
for locale, values in pairs(timing) do
    for index, kind in ipairs({ "minTime", "chromieTime", "chromieTimeID" }) do
        Lib.locales[locale]["NAVIGATION_REQUIRES_" .. kind] = values[index]
    end
end

local availability = {
    enUS = { "Quest availability is unverified: %s", "Quest unavailable: %s" },
    frFR = { "Disponibilité de la quête non vérifiée : %s", "Quête indisponible : %s" },
    deDE = { "Questverfügbarkeit nicht bestätigt: %s", "Quest nicht verfügbar: %s" },
    esES = { "Disponibilidad de misión sin verificar: %s", "Misión no disponible: %s" },
    esMX = { "Disponibilidad de misión sin verificar: %s", "Misión no disponible: %s" },
    itIT = { "Disponibilità della missione non verificata: %s", "Missione non disponibile: %s" },
    koKR = { "퀘스트 수락 가능 여부가 확인되지 않았습니다: %s", "수락할 수 없는 퀘스트: %s" },
    ptBR = { "Disponibilidade da missão não verificada: %s", "Missão indisponível: %s" },
    ruRU = { "Доступность задания не подтверждена: %s", "Задание недоступно: %s" },
    zhCN = { "任务可用性尚未核实：%s", "任务不可接取：%s" },
    zhTW = { "任務可用性尚未核實：%s", "任務無法接取：%s" },
}
for locale, values in pairs(availability) do
    Lib.locales[locale].NAVIGATION_UNLOCK_accept_unverified = values[1]
    Lib.locales[locale].NAVIGATION_UNLOCK_accept_unavailable = values[2]
end

local actions = {
    enUS = { "Buy %s", "Discover the flight point", "Set your hearthstone", "Enter the vehicle", "Leave the vehicle", "Dismount", "Use your hearthstone", "Enter the instance", "Leave the instance", "Enter the scenario", "Leave the scenario", "Use your Dalaran hearthstone", "Use your garrison hearthstone" },
    frFR = { "Achète %s", "Découvre le maître de vol", "Définis ton foyer", "Monte dans le véhicule", "Quitte le véhicule", "Descends de monture", "Utilise ta pierre de foyer", "Entre dans l'instance", "Quitte l'instance", "Entre dans le scénario", "Quitte le scénario", "Utilise ta pierre de foyer de Dalaran", "Utilise ta pierre de foyer de fief" },
    deDE = { "Kaufe %s", "Entdecke den Flugpunkt", "Setze deinen Ruhestein", "Steige in das Fahrzeug", "Verlasse das Fahrzeug", "Steige ab", "Benutze deinen Ruhestein", "Betritt die Instanz", "Verlasse die Instanz", "Betritt das Szenario", "Verlasse das Szenario", "Benutze deinen Dalaranruhestein", "Benutze deinen Garnisonsruhestein" },
    esES = { "Compra %s", "Descubre el punto de vuelo", "Fija tu hogar", "Entra en el vehículo", "Sal del vehículo", "Desmonta", "Usa tu piedra de hogar", "Entra en la estancia", "Sal de la estancia", "Entra en la gesta", "Sal de la gesta", "Usa tu piedra de hogar de Dalaran", "Usa tu piedra de hogar de la ciudadela" },
    esMX = { "Compra %s", "Descubre el punto de vuelo", "Fija tu hogar", "Entra en el vehículo", "Sal del vehículo", "Desmonta", "Usa tu piedra de hogar", "Entra en la estancia", "Sal de la estancia", "Entra en la gesta", "Sal de la gesta", "Usa tu piedra de hogar de Dalaran", "Usa tu piedra de hogar de la ciudadela" },
    itIT = { "Compra %s", "Scopri il punto di volo", "Imposta la tua dimora", "Entra nel veicolo", "Esci dal veicolo", "Scendi dalla cavalcatura", "Usa la tua Pietra del Ritorno", "Entra nell’istanza", "Esci dall’istanza", "Entra nello scenario", "Esci dallo scenario", "Usa la Pietra del Ritorno di Dalaran", "Usa la Pietra del Ritorno della Guarnigione" },
    koKR = { "%s 구매", "비행 경로 발견", "귀환 지점 설정", "탈것에 탑승", "탈것에서 내리기", "탈것 내리기", "귀환석 사용", "인스턴스 입장", "인스턴스 떠나기", "시나리오 입장", "시나리오 떠나기", "달라란 귀환석 사용", "주둔지 귀환석 사용" },
    ptBR = { "Compre %s", "Descubra o ponto de voo", "Defina seu lar", "Entre no veículo", "Saia do veículo", "Desmonte", "Use sua Pedra de Regresso", "Entre na instância", "Saia da instância", "Entre no cenário", "Saia do cenário", "Use sua Pedra de Regresso de Dalaran", "Use sua Pedra de Regresso da Guarnição" },
    ruRU = { "Купите %s", "Откройте точку полетов", "Установите место возвращения", "Сядьте в транспорт", "Покиньте транспорт", "Спешьтесь", "Используйте камень возвращения", "Войдите в подземелье", "Покиньте подземелье", "Войдите в сценарий", "Покиньте сценарий", "Используйте даларанский камень возвращения", "Используйте гарнизонный камень возвращения" },
    zhCN = { "购买%s", "发现飞行点", "设置炉石位置", "进入载具", "离开载具", "取消坐骑", "使用炉石", "进入副本", "离开副本", "进入场景战役", "离开场景战役", "使用达拉然炉石", "使用要塞炉石" },
    zhTW = { "購買%s", "發現飛行點", "設定爐石位置", "進入載具", "離開載具", "取消坐騎", "使用爐石", "進入副本", "離開副本", "進入事件", "離開事件", "使用達拉然爐石", "使用要塞爐石" },
}
for locale, values in pairs(actions) do
    for index, kind in ipairs({ "buy", "discover_flight", "bind_hearthstone", "mount_vehicle", "exit_vehicle", "dismount",
        "hearthstone", "enter_instance", "leave_instance", "enter_scenario", "leave_scenario", "dalaran_hearthstone", "garrison_hearthstone" }) do
        Lib.locales[locale]["NAVIGATION_UNLOCK_" .. kind] = values[index]
    end
end
