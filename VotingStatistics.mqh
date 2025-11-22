//+------------------------------------------------------------------+
//| AdaptiveVotingSystem.mqh - Sistema de Votación Adaptativo v4.0  |
//| Sistema inteligente que aprende y especializa indicadores       |
//+------------------------------------------------------------------+
#ifndef ADAPTIVE_VOTING_SYSTEM_MQH
#define ADAPTIVE_VOTING_SYSTEM_MQH

#property copyright "Advanced Trading System 2025"
#property version   "4.00"
#property strict

//+------------------------------------------------------------------+
//| ENUMERACIONES                                                     |
//+------------------------------------------------------------------+

// Sesiones de trading
enum ENUM_TRADING_SESSION {
    SESSION_ASIA    = 0,  // 00:00-08:00 GMT
    SESSION_LONDON  = 1,  // 08:00-16:00 GMT
    SESSION_NY      = 2   // 13:00-22:00 GMT
};

// Niveles de volatilidad
enum ENUM_VOLATILITY_LEVEL {
    VOL_LOW     = 0,  // ATR < percentil 40
    VOL_HIGH    = 1   // ATR >= percentil 40
};

// Dirección del mercado
enum ENUM_MARKET_DIRECTION {
    DIR_BEARISH = 0,  // Bajista
    DIR_BULLISH = 1   // Alcista
};

// Régimen de mercado - Usar definición de RegimeDetectionSystem.mqh
// ENUM_MARKET_REGIME se define en RegimeDetectionSystem.mqh con valores completos
#include <RegimeDetectionSystem.mqh>

//+------------------------------------------------------------------+
//| ESTRUCTURAS COMUNES DEL SISTEMA                                 |
//+------------------------------------------------------------------+

// Enumeración de Dirección de Voto
enum ENUM_VOTE_DIRECTION {
    VOTE_NEUTRAL = 0,   // Sin dirección clara
    VOTE_NONE    = 0,   // Alias para VOTE_NEUTRAL
    VOTE_BUY     = 1,   // Voto de compra
    VOTE_SELL    = -1   // Voto de venta
};

// Tipos de componentes del sistema
enum ENUM_COMPONENT_TYPE {
    COMPONENT_SUPPORT_RESIST = 0,
    COMPONENT_ACCUM_ZONES = 1,
    COMPONENT_PATTERN_MEMORY = 2,
    COMPONENT_BREAKOUT_DETECT = 3,
    COMPONENT_INSTITUTIONAL = 4
};

// Estructura de Emoción de Mercado
struct MarketEmotion {
    double fear;           // Nivel de miedo (0-1)
    double greed;          // Nivel de codicia (0-1)
    double uncertainty;    // Nivel de incertidumbre (0-1)
    double excitement;     // Nivel de excitación (0-1)

    void Initialize() {
        fear = 0.5;
        greed = 0.5;
        uncertainty = 0.5;
        excitement = 0.5;
    }
};

// Estructura de Contexto de Decisión
struct DecisionContext {
    datetime timestamp;
    double atr;
    double momentum;
    double volatility;
    int session;
    double market_strength;
    bool high_confidence;
    string context_description;

    void Initialize() {
        timestamp = 0;
        atr = 0.0;
        momentum = 0.0;
        volatility = 0.0;
        session = 0;
        market_strength = 0.0;
        high_confidence = false;
        context_description = "";
    }
};

// Estructura de Memoria de Consenso
struct ConsensusMemory {
    ulong consensus_id;
    ulong associated_ticket;
    datetime timestamp;
    double consensus_strength;
    int agent_count;
    ENUM_VOTE_DIRECTION direction;
    bool was_successful;
    double emotional_score;
    double profit_result;
    int negotiation_rounds;
    string dominant_agent;
    double agreement_level;
    double profit_points;
    int duration_bars;
    double max_favorable_excursion;
    double max_adverse_excursion;

    // Arrays de agentes
    string participating_agents[5];
    double agent_confidences[5];
    ENUM_VOTE_DIRECTION agent_votes[5];

    // Contexto de decisión
    DecisionContext context;

    void Initialize() {
        consensus_id = 0;
        associated_ticket = 0;
        timestamp = 0;
        consensus_strength = 0.0;
        agent_count = 0;
        direction = VOTE_NEUTRAL;
        was_successful = false;
        emotional_score = 0.0;
        profit_result = 0.0;
        negotiation_rounds = 0;
        dominant_agent = "";
        agreement_level = 0.0;
        profit_points = 0.0;
        duration_bars = 0;
        max_favorable_excursion = 0.0;
        max_adverse_excursion = 0.0;

        for(int i = 0; i < 5; i++) {
            participating_agents[i] = "";
            agent_confidences[i] = 0.0;
            agent_votes[i] = VOTE_NEUTRAL;
        }
    }
};

// Estructura de Resultado de Consenso Neural
struct NeuralConsensusResult {
    ENUM_VOTE_DIRECTION final_direction;
    double consensus_strength;
    double total_conviction;
    double negotiation_rounds;
    string consensus_reasoning;
    bool strong_consensus;
    int dissenting_agents;
    string leading_agent;
    double leadership_strength;
    bool veto_used;
    ulong consensus_id;
    MarketEmotion market_emotion;

    void Initialize() {
        final_direction = VOTE_NEUTRAL;
        consensus_strength = 0.0;
        total_conviction = 0.0;
        negotiation_rounds = 0;
        consensus_reasoning = "";
        strong_consensus = false;
        dissenting_agents = 0;
        leading_agent = "";
        leadership_strength = 0.0;
        veto_used = false;
        consensus_id = 0;
        market_emotion.Initialize();
    }
};

// Nivel de expertise del indicador en un contexto
enum ENUM_EXPERTISE_LEVEL {
    EXPERTISE_NONE      = 0,  // Sin datos suficientes
    EXPERTISE_NOVICE    = 1,  // WR 45-52%, < 30 trades
    EXPERTISE_COMPETENT = 2,  // WR 52-58%, >= 30 trades
    EXPERTISE_EXPERT    = 3,  // WR 58-65%, >= 50 trades, Sharpe > 1.0
    EXPERTISE_MASTER    = 4   // WR > 65%, >= 100 trades, Sharpe > 1.5
};

//+------------------------------------------------------------------+
//| ESTRUCTURAS DE DATOS                                             |
//+------------------------------------------------------------------+

//--- Snapshot completo del contexto actual del mercado
struct MarketContextSnapshot {
    // Contexto temporal
    ENUM_TRADING_SESSION session;
    int hourGMT;
    int dayOfWeek;  // 0=Domingo, 1=Lunes, ..., 6=Sábado
    datetime timestamp;

    // Contexto de mercado
    ENUM_VOLATILITY_LEVEL volatility;
    ENUM_MARKET_DIRECTION direction;
    ENUM_MARKET_REGIME regime;

    // Métricas cuantitativas
    double atrValue;
    double atrPercentile;        // Percentil del ATR actual (0-100)
    double spreadValue;
    double spreadPercentile;     // Percentil del spread actual (0-100)
    double momentumStrength;     // Fuerza del momentum (0-1)
    double trendStrength;        // Fuerza de tendencia ADX normalizado (0-1)

    // Hash único del contexto (para búsqueda rápida)
    string contextID;

    void Initialize() {
        session = SESSION_ASIA;
        hourGMT = 0;
        dayOfWeek = 0;
        timestamp = 0;
        volatility = VOL_LOW;
        direction = DIR_BULLISH;
        regime = REGIME_RANGING;  // Valor por defecto
        atrValue = 0.0;
        atrPercentile = 50.0;
        spreadValue = 0.0;
        spreadPercentile = 50.0;
        momentumStrength = 0.5;
        trendStrength = 0.5;
        contextID = "";
    }

    // Generar ID único del contexto
    string GenerateID() {
        contextID = StringFormat("%d_%d_%d_%d",
            (int)session,
            (int)volatility,
            (int)direction,
            (int)regime);
        return contextID;
    }
};

//--- Métricas detalladas de performance
struct PerformanceMetrics {
    // Contadores básicos
    int totalTrades;
    int wins;
    int losses;

    // Win Rate y variaciones
    double winRate;              // Ratio simple wins/total
    double emaWinRate;           // EMA del win rate (alpha=0.1)
    double winRateStdDev;        // Desviación estándar del WR

    // Profit metrics
    double totalProfit;
    double avgWinProfit;
    double avgLossProfit;
    double profitFactor;         // avgWin / |avgLoss|
    double emaProfit;            // EMA del profit (alpha=0.15)

    // Risk-adjusted metrics
    double sharpeRatio;          // (avgProfit - riskFree) / stdDevProfit
    double maxDrawdown;
    double currentDrawdown;
    double recoveryFactor;       // totalProfit / maxDrawdown

    // Streaks
    int currentStreak;           // Positivo=wins consecutivos, negativo=losses
    int maxWinStreak;
    int maxLossStreak;

    // Consistency metrics
    double consistencyScore;     // Medida de confiabilidad (0-1)
    double volatilityScore;      // Volatilidad de resultados (0-1, menor=mejor)

    // Temporal
    datetime lastTradeTime;
    datetime lastWinTime;
    double avgBarsToProfit;      // Promedio de barras hasta TP

    // Tendencia de performance
    double performanceTrend;     // -1=empeorando, 0=estable, +1=mejorando
    int tradesInTrend;           // Trades analizados para la tendencia

    void Initialize() {
        totalTrades = 0;
        wins = 0;
        losses = 0;
        winRate = 0.5;
        emaWinRate = 0.5;
        winRateStdDev = 0.0;
        totalProfit = 0.0;
        avgWinProfit = 0.0;
        avgLossProfit = 0.0;
        profitFactor = 1.0;
        emaProfit = 0.0;
        sharpeRatio = 0.0;
        maxDrawdown = 0.0;
        currentDrawdown = 0.0;
        recoveryFactor = 0.0;
        currentStreak = 0;
        maxWinStreak = 0;
        maxLossStreak = 0;
        consistencyScore = 0.5;
        volatilityScore = 0.5;
        lastTradeTime = 0;
        lastWinTime = 0;
        avgBarsToProfit = 0.0;
        performanceTrend = 0.0;
        tradesInTrend = 0;
    }

    // Actualizar métricas después de un trade
    void Update(bool won, double profit, int barsToClose = 0) {
        totalTrades++;

        if(won) {
            wins++;
            currentStreak = (currentStreak >= 0) ? currentStreak + 1 : 1;
            if(currentStreak > maxWinStreak) maxWinStreak = currentStreak;
            lastWinTime = TimeCurrent();
            avgWinProfit = (avgWinProfit * (wins - 1) + profit) / wins;
        } else {
            losses++;
            currentStreak = (currentStreak <= 0) ? currentStreak - 1 : -1;
            if(-currentStreak > maxLossStreak) maxLossStreak = -currentStreak;
            avgLossProfit = (avgLossProfit * (losses - 1) + profit) / losses;
        }

        // Actualizar win rate
        winRate = (totalTrades > 0) ? (double)wins / totalTrades : 0.5;

        // Actualizar EMA del win rate
        double alpha = 0.1;
        emaWinRate = alpha * (won ? 1.0 : 0.0) + (1.0 - alpha) * emaWinRate;
        emaWinRate = MathMax(0.0, MathMin(1.0, emaWinRate));

        // Actualizar profit
        totalProfit += profit;

        // Actualizar EMA del profit
        double alphaProfit = 0.15;
        emaProfit = alphaProfit * profit + (1.0 - alphaProfit) * emaProfit;

        // Actualizar drawdown
        if(profit < 0) {
            currentDrawdown += MathAbs(profit);
            if(currentDrawdown > maxDrawdown) {
                maxDrawdown = currentDrawdown;
            }
        } else {
            currentDrawdown = MathMax(0.0, currentDrawdown - profit);
        }

        // Calcular profit factor
        if(losses > 0 && MathAbs(avgLossProfit) > 0.001) {
            profitFactor = avgWinProfit / MathAbs(avgLossProfit);
        } else {
            profitFactor = (wins > 0) ? 10.0 : 1.0;
        }

        // Actualizar recovery factor
        if(maxDrawdown > 0.001) {
            recoveryFactor = totalProfit / maxDrawdown;
        }

        // Actualizar tiempo promedio
        if(barsToClose > 0) {
            avgBarsToProfit = (avgBarsToProfit * (totalTrades - 1) + barsToClose) / totalTrades;
        }

        lastTradeTime = TimeCurrent();

        // Recalcular métricas derivadas
        RecalculateMetrics();
    }

    // Recalcular Sharpe, consistencia, etc.
    void RecalculateMetrics() {
        // Sharpe Ratio simplificado (asumiendo risk-free = 0)
        if(totalTrades >= 10) {
            double avgProfit = totalProfit / totalTrades;
            // Aproximación de stdDev usando varianza del win/loss
            double variance = (wins * MathPow(avgWinProfit - avgProfit, 2) +
                             losses * MathPow(avgLossProfit - avgProfit, 2)) / totalTrades;
            double stdDev = MathSqrt(variance);

            if(stdDev > 0.001) {
                sharpeRatio = avgProfit / stdDev;
            } else {
                sharpeRatio = 0.0;
            }
        }

        // Consistency Score: combinación de WR estable y Sharpe alto
        double wrFactor = MathMin(1.0, winRate / 0.65);  // Normalizado a 65% WR = 1.0
        double sharpeFactor = MathMin(1.0, (sharpeRatio + 1.0) / 3.0);  // Sharpe 2.0 = 1.0
        double streakFactor = 1.0 - (MathMin(10, maxLossStreak) / 10.0) * 0.3;

        consistencyScore = (wrFactor * 0.4 + sharpeFactor * 0.4 + streakFactor * 0.2);
        consistencyScore = MathMax(0.0, MathMin(1.0, consistencyScore));

        // Volatility Score: menor es mejor
        if(totalTrades >= 20) {
            double wrRange = MathMax(0.01, winRateStdDev);
            volatilityScore = 1.0 - MathMin(1.0, wrRange / 0.3);  // 30% stdDev = score 0
        }

        // Performance Trend: comparar últimos 20 trades vs previos 20
        if(totalTrades >= 40) {
            // Simplificación: comparar EMA reciente vs WR histórico
            if(emaWinRate > winRate + 0.05) {
                performanceTrend = 1.0;  // Mejorando
            } else if(emaWinRate < winRate - 0.05) {
                performanceTrend = -1.0;  // Empeorando
            } else {
                performanceTrend = 0.0;  // Estable
            }
        }
    }
};

//--- Celda de performance contextual (un indicador en un contexto específico)
struct ContextualPerformanceCell {
    MarketContextSnapshot context;
    PerformanceMetrics metrics;

    // Nivel de expertise en este contexto
    ENUM_EXPERTISE_LEVEL expertiseLevel;

    // Confiabilidad de los datos
    bool hasEnoughSamples;       // true si >= 20 trades
    bool isReliable;             // true si >= 50 trades && consistencyScore > 0.6

    // Timestamp
    datetime lastUpdate;
    datetime firstTrade;

    // Distribución temporal dentro del contexto
    int tradesByHour[24];        // Distribución de trades por hora
    int tradesByDay[5];          // Distribución por día (0=Lun, 4=Vie)

    void Initialize() {
        context.Initialize();
        metrics.Initialize();
        expertiseLevel = EXPERTISE_NONE;
        hasEnoughSamples = false;
        isReliable = false;
        lastUpdate = 0;
        firstTrade = 0;
        ArrayInitialize(tradesByHour, 0);
        ArrayInitialize(tradesByDay, 0);
    }

    // Actualizar con nuevo resultado
    void UpdateResult(bool won, double profit, int hour, int day, int bars = 0) {
        if(firstTrade == 0) firstTrade = TimeCurrent();

        metrics.Update(won, profit, bars);
        lastUpdate = TimeCurrent();

        // Actualizar distribuciones temporales
        if(hour >= 0 && hour < 24) tradesByHour[hour]++;
        if(day >= 0 && day < 5) tradesByDay[day]++;

        // Recalcular expertise level
        UpdateExpertiseLevel();

        // Actualizar flags de confiabilidad
        hasEnoughSamples = (metrics.totalTrades >= 20);
        isReliable = (metrics.totalTrades >= 50 && metrics.consistencyScore > 0.6);
    }

    // Determinar nivel de expertise basado en métricas
    void UpdateExpertiseLevel() {
        if(metrics.totalTrades < 10) {
            expertiseLevel = EXPERTISE_NONE;
            return;
        }

        if(metrics.totalTrades < 30 || metrics.winRate < 0.52) {
            expertiseLevel = EXPERTISE_NOVICE;
        } else if(metrics.totalTrades < 50 || metrics.winRate < 0.58 || metrics.sharpeRatio < 1.0) {
            expertiseLevel = EXPERTISE_COMPETENT;
        } else if(metrics.totalTrades < 100 || metrics.winRate < 0.65 || metrics.sharpeRatio < 1.5) {
            expertiseLevel = EXPERTISE_EXPERT;
        } else {
            expertiseLevel = EXPERTISE_MASTER;
        }
    }

    // Obtener score de performance (0-1, usado para ranking)
    double GetPerformanceScore() {
        if(!hasEnoughSamples) return 0.3;  // Score bajo si no hay datos

        double wrScore = metrics.winRate;
        double sharpeScore = MathMin(1.0, (metrics.sharpeRatio + 1.0) / 3.0);
        double consistencyScore = metrics.consistencyScore;
        double profitScore = MathMin(1.0, metrics.profitFactor / 3.0);

        // Peso balanceado
        return wrScore * 0.35 + sharpeScore * 0.25 + consistencyScore * 0.25 + profitScore * 0.15;
    }
};

//--- Especialización de un indicador
struct IndicatorSpecialization {
    int indicatorId;
    string indicatorName;

    // Contextos donde es EXPERTO (expertise >= EXPERT)
    string expertContexts[20];
    int expertContextCount;

    // Contextos donde es COMPETENTE
    string competentContexts[30];
    int competentContextCount;

    // Mejor contexto overall
    string bestContextID;
    double bestContextScore;
    ENUM_EXPERTISE_LEVEL bestContextExpertise;

    // Estadísticas globales (todos los contextos combinados)
    PerformanceMetrics globalMetrics;

    // Ranking general (1-5, siendo 1 el mejor indicador global)
    int globalRank;

    void Initialize(int id, string name) {
        indicatorId = id;
        indicatorName = name;
        expertContextCount = 0;
        competentContextCount = 0;
        bestContextID = "";
        bestContextScore = 0.0;
        bestContextExpertise = EXPERTISE_NONE;
        globalMetrics.Initialize();
        globalRank = 5;

        // Inicializar arrays de strings manualmente
        for(int i = 0; i < 20; i++) {
            expertContexts[i] = "";
        }
        for(int i = 0; i < 30; i++) {
            competentContexts[i] = "";
        }
    }

    // Agregar un contexto experto
    void AddExpertContext(string contextID) {
        if(expertContextCount < 20) {
            expertContexts[expertContextCount] = contextID;
            expertContextCount++;
        }
    }

    // Verificar si es experto en un contexto
    bool IsExpertIn(string contextID) {
        for(int i = 0; i < expertContextCount; i++) {
            if(expertContexts[i] == contextID) return true;
        }
        return false;
    }

    // Obtener descripción de especialización
    string GetSpecializationSummary() {
        return StringFormat("%s: Rank #%d | Best: %s (Score: %.2f) | Expert in %d contexts",
            indicatorName, globalRank, bestContextID, bestContextScore, expertContextCount);
    }
};

//--- Peso dinámico calculado para votación
struct DynamicWeight {
    int indicatorId;
    string indicatorName;

    // Componentes del peso
    double contextMatchScore;    // Qué tan bien match el contexto actual (0-1)
    double performanceScore;     // Score de performance en este contexto (0-1)
    double expertiseBonus;       // Bonus si es experto en este contexto (0-0.3)
    double trendBonus;           // Bonus si está mejorando (0-0.2)
    double streakBonus;          // Bonus por racha positiva (0-0.15)
    double globalWeight;         // Peso global del indicador (0.15-0.25)

    // Penalizaciones
    double degradationPenalty;   // Penalización si está empeorando (0-0.3)
    double unreliabilityPenalty; // Penalización si no es confiable (0-0.2)

    // Peso final calculado
    double finalWeight;          // Producto de todos los factores
    bool isActive;               // false si está filtrado (peso muy bajo)

    // Razón del cálculo (para debugging)
    string reasoning;

    void Initialize() {
        contextMatchScore = 0.5;
        performanceScore = 0.5;
        expertiseBonus = 0.0;
        trendBonus = 0.0;
        streakBonus = 0.0;
        globalWeight = 0.20;
        degradationPenalty = 0.0;
        unreliabilityPenalty = 0.0;
        finalWeight = 0.20;
        isActive = true;
        reasoning = "";
    }

    // Calcular peso final
    void Calculate() {
        // Fórmula: (Base + Bonuses - Penalties) × ContextMatch × Performance
        double baseWeight = globalWeight;
        double bonuses = expertiseBonus + trendBonus + streakBonus;
        double penalties = degradationPenalty + unreliabilityPenalty;

        finalWeight = (baseWeight + bonuses - penalties) * contextMatchScore * performanceScore;

        // Limitar rango
        finalWeight = MathMax(0.05, MathMin(0.50, finalWeight));

        // Filtrar si es demasiado bajo
        isActive = (finalWeight >= 0.08);

        // Generar reasoning
        reasoning = StringFormat("Base:%.2f Match:%.2f Perf:%.2f Exp:+%.2f Trend:+%.2f Streak:+%.2f Deg:-%.2f → %.3f %s",
            baseWeight, contextMatchScore, performanceScore,
            expertiseBonus, trendBonus, streakBonus, degradationPenalty,
            finalWeight, isActive ? "✓" : "✗");
    }
};

//--- Resultado de votación
struct VotingResult {
    // Decisión final
    int finalDirection;          // 1=BUY, -1=SELL, 0=NEUTRAL
    double confidence;           // 0-1
    bool hasConsensus;

    // Participación
    int activeIndicators;
    int totalIndicators;

    // Contexto usado
    MarketContextSnapshot context;

    // Pesos aplicados
    DynamicWeight weights[5];

    // Top indicador
    int topIndicatorId;
    string topIndicatorName;
    double topIndicatorWeight;

    // Metadata
    datetime decisionTime;
    string decisionReason;

    void Initialize() {
        finalDirection = 0;
        confidence = 0.0;
        hasConsensus = false;
        activeIndicators = 0;
        totalIndicators = 5;
        topIndicatorId = -1;
        topIndicatorName = "";
        topIndicatorWeight = 0.0;
        decisionTime = TimeCurrent();
        decisionReason = "";
        context.Initialize();
    }
};

//+------------------------------------------------------------------+
//| CLASE: ContextDetector - Detecta el contexto actual del mercado |
//+------------------------------------------------------------------+
class ContextDetector {
private:
    // Historial de ATR para cálculo de percentiles
    double m_atrHistory[200];
    int m_atrHistoryCount;

    // Historial de spreads
    double m_spreadHistory[200];
    int m_spreadHistoryCount;

    // Handles de indicadores
    int m_atrHandle;
    int m_adxHandle;
    int m_maFastHandle;
    int m_maSlowHandle;

    string m_symbol;
    ENUM_TIMEFRAMES m_timeframe;

public:
    ContextDetector() {
        m_atrHistoryCount = 0;
        m_spreadHistoryCount = 0;
        m_atrHandle = INVALID_HANDLE;
        m_adxHandle = INVALID_HANDLE;
        m_maFastHandle = INVALID_HANDLE;
        m_maSlowHandle = INVALID_HANDLE;
        m_symbol = _Symbol;
        m_timeframe = PERIOD_CURRENT;

        ArrayInitialize(m_atrHistory, 0.0);
        ArrayInitialize(m_spreadHistory, 0.0);
    }

    ~ContextDetector() {
        if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
        if(m_adxHandle != INVALID_HANDLE) IndicatorRelease(m_adxHandle);
        if(m_maFastHandle != INVALID_HANDLE) IndicatorRelease(m_maFastHandle);
        if(m_maSlowHandle != INVALID_HANDLE) IndicatorRelease(m_maSlowHandle);
    }

    bool Initialize(string symbol = "", ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT) {
        if(symbol != "") m_symbol = symbol;
        m_timeframe = timeframe;

        // Crear handles de indicadores
        m_atrHandle = iATR(m_symbol, m_timeframe, 14);
        m_adxHandle = iADX(m_symbol, m_timeframe, 14);
        m_maFastHandle = iMA(m_symbol, m_timeframe, 20, 0, MODE_EMA, PRICE_CLOSE);
        m_maSlowHandle = iMA(m_symbol, m_timeframe, 50, 0, MODE_EMA, PRICE_CLOSE);

        if(m_atrHandle == INVALID_HANDLE || m_adxHandle == INVALID_HANDLE ||
           m_maFastHandle == INVALID_HANDLE || m_maSlowHandle == INVALID_HANDLE) {
            Print("ERROR: ContextDetector - Failed to create indicators");
            return false;
        }

        Print("✓ ContextDetector initialized for ", m_symbol);
        return true;
    }

    // Detectar contexto completo actual
    MarketContextSnapshot DetectCurrentContext() {
        MarketContextSnapshot context;
        context.Initialize();
        context.timestamp = TimeCurrent();

        // Detectar contexto temporal
        MqlDateTime dt;
        TimeToStruct(TimeGMT(), dt);
        context.hourGMT = dt.hour;
        context.dayOfWeek = dt.day_of_week;
        context.session = DetectSession(dt.hour);

        // Detectar volatilidad
        double atr = GetCurrentATR();
        context.atrValue = atr;
        context.atrPercentile = CalculateATRPercentile(atr);
        context.volatility = (context.atrPercentile >= 40.0) ? VOL_HIGH : VOL_LOW;

        // Detectar spread
        double spread = GetCurrentSpread();
        context.spreadValue = spread;
        context.spreadPercentile = CalculateSpreadPercentile(spread);

        // Detectar dirección primero (necesario para régimen)
        double maFast = GetMA(m_maFastHandle);
        double maSlow = GetMA(m_maSlowHandle);
        context.direction = (maFast > maSlow) ? DIR_BULLISH : DIR_BEARISH;

        // Detectar régimen de mercado
        double adx = GetCurrentADX();
        context.trendStrength = MathMin(1.0, adx / 50.0);  // Normalizar ADX a 0-1

        if(adx > 25.0) {
            context.regime = (context.direction == DIR_BULLISH) ? REGIME_TRENDING_UP : REGIME_TRENDING_DOWN;
        } else if(adx < 20.0) {
            context.regime = REGIME_RANGING;
        } else {
            context.regime = REGIME_TRANSITION;
        }

        // Calcular momentum
        context.momentumStrength = CalculateMomentumStrength(maFast, maSlow, atr);

        // Generar ID único
        context.GenerateID();

        return context;
    }

private:
    ENUM_TRADING_SESSION DetectSession(int hourGMT) {
        // Overlap NY-London tiene prioridad (13:00-16:00 GMT)
        if(hourGMT >= 13 && hourGMT < 16) return SESSION_NY;

        // Londres (08:00-16:00 GMT)
        if(hourGMT >= 8 && hourGMT < 16) return SESSION_LONDON;

        // Nueva York (13:00-22:00 GMT)
        if(hourGMT >= 13 && hourGMT < 22) return SESSION_NY;

        // Asia (resto)
        return SESSION_ASIA;
    }

    double GetCurrentATR() {
        double buffer[];
        ArraySetAsSeries(buffer, true);
        if(CopyBuffer(m_atrHandle, 0, 0, 1, buffer) > 0) {
            double atr = buffer[0];
            AddToATRHistory(atr);
            return atr;
        }
        return 0.0;
    }

    double GetCurrentADX() {
        double buffer[];
        ArraySetAsSeries(buffer, true);
        if(CopyBuffer(m_adxHandle, 0, 0, 1, buffer) > 0) {
            return buffer[0];
        }
        return 20.0;  // Neutral por defecto
    }

    double GetMA(int handle) {
        double buffer[];
        ArraySetAsSeries(buffer, true);
        if(CopyBuffer(handle, 0, 0, 1, buffer) > 0) {
            return buffer[0];
        }
        return 0.0;
    }

    double GetCurrentSpread() {
        double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
        double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
        double spread = ask - bid;
        AddToSpreadHistory(spread);
        return spread;
    }

    void AddToATRHistory(double atr) {
        if(m_atrHistoryCount < 200) {
            m_atrHistory[m_atrHistoryCount] = atr;
            m_atrHistoryCount++;
        } else {
            // Shift array
            for(int i = 0; i < 199; i++) {
                m_atrHistory[i] = m_atrHistory[i + 1];
            }
            m_atrHistory[199] = atr;
        }
    }

    void AddToSpreadHistory(double spread) {
        if(m_spreadHistoryCount < 200) {
            m_spreadHistory[m_spreadHistoryCount] = spread;
            m_spreadHistoryCount++;
        } else {
            for(int i = 0; i < 199; i++) {
                m_spreadHistory[i] = m_spreadHistory[i + 1];
            }
            m_spreadHistory[199] = spread;
        }
    }

    double CalculateATRPercentile(double currentATR) {
        if(m_atrHistoryCount < 10) return 50.0;

        int countBelow = 0;
        for(int i = 0; i < m_atrHistoryCount; i++) {
            if(m_atrHistory[i] < currentATR) countBelow++;
        }

        return (countBelow * 100.0) / m_atrHistoryCount;
    }

    double CalculateSpreadPercentile(double currentSpread) {
        if(m_spreadHistoryCount < 10) return 50.0;

        int countBelow = 0;
        for(int i = 0; i < m_spreadHistoryCount; i++) {
            if(m_spreadHistory[i] < currentSpread) countBelow++;
        }

        return (countBelow * 100.0) / m_spreadHistoryCount;
    }

    double CalculateMomentumStrength(double maFast, double maSlow, double atr) {
        if(atr <= 0.0 || maFast == 0.0 || maSlow == 0.0) return 0.5;

        double maDiff = MathAbs(maFast - maSlow);
        double normalizedDiff = maDiff / atr;  // Normalizado por ATR

        // Momentum fuerte si diff > 2 ATR
        return MathMin(1.0, normalizedDiff / 2.0);
    }
};

//+------------------------------------------------------------------+
//| CLASE: AdaptiveVotingSystem - Sistema Principal                 |
//+------------------------------------------------------------------+
class AdaptiveVotingSystem {
private:
    // Componentes
    ContextDetector m_contextDetector;

    // Matriz de performance 4D: [Indicador][Sesión][Volatilidad][Dirección]
    // 5 indicadores × 3 sesiones × 2 volatilidades × 2 direcciones = 60 celdas
    ContextualPerformanceCell m_performanceMatrix[5][3][2][2];

    // Especializaciones de indicadores
    IndicatorSpecialization m_specializations[5];

    // Configuración
    int m_minSamplesForReliability;
    int m_tradesUntilReeval;
    int m_tradesSinceLastReeval;
    double m_minWeightThreshold;
    double m_consensusThreshold;

    // Estadísticas globales
    int m_totalSystemTrades;
    datetime m_systemStartTime;
    datetime m_lastReevalTime;

    // Último contexto y resultado
    MarketContextSnapshot m_lastContext;
    VotingResult m_lastVotingResult;

    // Persistencia
    int m_tradesUntilSave;
    int m_tradesSinceLastSave;

public:
    AdaptiveVotingSystem() {
        m_minSamplesForReliability = 20;
        m_tradesUntilReeval = 100;
        m_tradesSinceLastReeval = 0;
        m_minWeightThreshold = 0.08;
        m_consensusThreshold = 0.65;
        m_totalSystemTrades = 0;
        m_systemStartTime = TimeCurrent();
        m_lastReevalTime = 0;
        m_tradesUntilSave = 50;
        m_tradesSinceLastSave = 0;
    }

    ~AdaptiveVotingSystem() {
        // Guardar al destruir
        SavePerformanceData();
    }

    //+------------------------------------------------------------------+
    //| Inicialización del sistema                                       |
    //+------------------------------------------------------------------+
    bool Initialize(string symbol = "", ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT) {
        Print("═══════════════════════════════════════════════════════════════");
        Print("  🧠 ADAPTIVE VOTING SYSTEM v4.0 - INICIALIZANDO");
        Print("═══════════════════════════════════════════════════════════════");

        // Inicializar detector de contexto
        if(!m_contextDetector.Initialize(symbol, timeframe)) {
            Print("❌ ERROR: No se pudo inicializar ContextDetector");
            return false;
        }

        // Inicializar matriz de performance
        for(int ind = 0; ind < 5; ind++) {
            for(int ses = 0; ses < 3; ses++) {
                for(int vol = 0; vol < 2; vol++) {
                    for(int dir = 0; dir < 2; dir++) {
                        m_performanceMatrix[ind][ses][vol][dir].Initialize();
                    }
                }
            }
        }

        // Inicializar especializaciones
        m_specializations[0].Initialize(0, "SR_Levels");
        m_specializations[1].Initialize(1, "ML_Neural");
        m_specializations[2].Initialize(2, "Momentum");
        m_specializations[3].Initialize(3, "RSI_Divergence");
        m_specializations[4].Initialize(4, "Volume_Profile");

        // Cargar datos históricos si existen
        LoadPerformanceData();

        // Realizar evaluación inicial
        ReevaluateSpecializations();

        Print("✅ Sistema inicializado correctamente");
        Print("   📊 Indicadores: 5");
        Print("   🧩 Celdas de contexto: 60 (5×3×2×2)");
        Print("   ⚙️ Re-evaluación cada: ", m_tradesUntilReeval, " trades");
        Print("   💾 Auto-guardado cada: ", m_tradesUntilSave, " trades");
        Print("═══════════════════════════════════════════════════════════════");

        return true;
    }

    //+------------------------------------------------------------------+
    //| Generar pesos dinámicos para votación                           |
    //+------------------------------------------------------------------+
    bool GenerateVotingWeights(DynamicWeight &weights[]) {
        // Detectar contexto actual
        m_lastContext = m_contextDetector.DetectCurrentContext();

        int ses = (int)m_lastContext.session;
        int vol = (int)m_lastContext.volatility;
        int dir = (int)m_lastContext.direction;

        // Validar índices
        ses = MathMax(0, MathMin(2, ses));
        vol = MathMax(0, MathMin(1, vol));
        dir = MathMax(0, MathMin(1, dir));

        // Calcular peso para cada indicador
        ArrayResize(weights, 5);

        for(int i = 0; i < 5; i++) {
            weights[i].Initialize();
            weights[i].indicatorId = i;
            weights[i].indicatorName = m_specializations[i].indicatorName;

            // Obtener celda de performance
            ContextualPerformanceCell cell = m_performanceMatrix[i][ses][vol][dir];

            // 1. Context Match Score (qué tan bien match)
            weights[i].contextMatchScore = CalculateContextMatch(i, m_lastContext);

            // 2. Performance Score
            weights[i].performanceScore = cell.GetPerformanceScore();

            // 3. Expertise Bonus
            if(cell.expertiseLevel == EXPERTISE_MASTER) {
                weights[i].expertiseBonus = 0.30;
            } else if(cell.expertiseLevel == EXPERTISE_EXPERT) {
                weights[i].expertiseBonus = 0.20;
            } else if(cell.expertiseLevel == EXPERTISE_COMPETENT) {
                weights[i].expertiseBonus = 0.10;
            }

            // 4. Trend Bonus (si está mejorando)
            if(cell.metrics.performanceTrend > 0.5) {
                weights[i].trendBonus = 0.15;
            } else if(cell.metrics.performanceTrend > 0.0) {
                weights[i].trendBonus = 0.08;
            }

            // 5. Streak Bonus
            if(cell.metrics.currentStreak >= 3) {
                weights[i].streakBonus = 0.15;
            } else if(cell.metrics.currentStreak >= 2) {
                weights[i].streakBonus = 0.08;
            }

            // 6. Degradation Penalty
            if(cell.metrics.performanceTrend < -0.5) {
                weights[i].degradationPenalty = 0.25;
            } else if(cell.metrics.performanceTrend < 0.0) {
                weights[i].degradationPenalty = 0.12;
            }

            // 7. Unreliability Penalty
            if(!cell.isReliable && cell.metrics.totalTrades >= 30) {
                weights[i].unreliabilityPenalty = 0.15;
            }

            // 8. Global Weight (de especialización general)
            double rankFactor = 1.0 - (m_specializations[i].globalRank - 1) * 0.04;
            weights[i].globalWeight = 0.20 * rankFactor;

            // Calcular peso final
            weights[i].Calculate();
        }

        // Normalizar pesos de indicadores activos
        NormalizeWeights(weights);

        return true;
    }

    //+------------------------------------------------------------------+
    //| Registrar voto de un componente (método stub)                   |
    //+------------------------------------------------------------------+
    bool RecordVote(ENUM_COMPONENT_TYPE component, ENUM_VOTE_DIRECTION direction, double confidence, string context) {
        // TODO: Implementar registro de votos por componente
        // Por ahora retorna true para permitir compilación
        return true;
    }

    //+------------------------------------------------------------------+
    //| Ejecutar votación con pesos dinámicos                           |
    //+------------------------------------------------------------------+
    VotingResult ExecuteVoting(int &signals[], double &confidences[], DynamicWeight &weights[]) {
        VotingResult result;
        result.Initialize();
        result.context = m_lastContext;
        result.decisionTime = TimeCurrent();

        // Copiar pesos (result.weights ya está dimensionado como [5])
        for(int i = 0; i < 5; i++) {
            result.weights[i] = weights[i];
        }

        // Calcular voto ponderado
        double buyScore = 0.0;
        double sellScore = 0.0;
        int activeCount = 0;

        int topInd = -1;
        double topWeight = 0.0;

        for(int i = 0; i < 5; i++) {
            if(!weights[i].isActive) continue;

            activeCount++;

            // signals[i]: 1=BUY, -1=SELL, 0=NEUTRAL
            // confidences[i]: 0.0-1.0

            double vote = signals[i] * confidences[i] * weights[i].finalWeight;

            if(signals[i] > 0) {
                buyScore += vote;
            } else if(signals[i] < 0) {
                sellScore += MathAbs(vote);
            }

            // Tracking top indicador
            if(weights[i].finalWeight > topWeight) {
                topWeight = weights[i].finalWeight;
                topInd = i;
            }
        }

        result.activeIndicators = activeCount;
        result.totalIndicators = 5;
        result.topIndicatorId = topInd;
        if(topInd >= 0) {
            result.topIndicatorName = m_specializations[topInd].indicatorName;
            result.topIndicatorWeight = topWeight;
        }

        // Determinar dirección final
        double totalScore = buyScore + sellScore;

        if(totalScore < 0.001) {
            result.finalDirection = 0;
            result.confidence = 0.0;
            result.hasConsensus = false;
            result.decisionReason = "No hay señales activas";
            return result;
        }

        // Calcular consenso
        double buyRatio = buyScore / totalScore;
        double sellRatio = sellScore / totalScore;

        if(buyRatio > m_consensusThreshold) {
            result.finalDirection = 1;
            result.confidence = buyRatio;
            result.hasConsensus = true;
            result.decisionReason = StringFormat("Consenso BUY %.1f%% (Top: %s)",
                buyRatio * 100, result.topIndicatorName);
        } else if(sellRatio > m_consensusThreshold) {
            result.finalDirection = -1;
            result.confidence = sellRatio;
            result.hasConsensus = true;
            result.decisionReason = StringFormat("Consenso SELL %.1f%% (Top: %s)",
                sellRatio * 100, result.topIndicatorName);
        } else {
            result.finalDirection = 0;
            result.confidence = MathMax(buyRatio, sellRatio);
            result.hasConsensus = false;
            result.decisionReason = StringFormat("Sin consenso (BUY:%.1f%% SELL:%.1f%%)",
                buyRatio * 100, sellRatio * 100);
        }

        m_lastVotingResult = result;
        return result;
    }

    //+------------------------------------------------------------------+
    //| Aprender de resultado de trade                                  |
    //+------------------------------------------------------------------+
    void LearnFromTrade(VotingResult &votingResult, bool won, double profit, int barsToClose = 0) {
        m_totalSystemTrades++;
        m_tradesSinceLastReeval++;
        m_tradesSinceLastSave++;

        // Extraer contexto
        int ses = (int)votingResult.context.session;
        int vol = (int)votingResult.context.volatility;
        int dir = (int)votingResult.finalDirection > 0 ? (int)DIR_BULLISH : (int)DIR_BEARISH;
        int hour = votingResult.context.hourGMT;
        int day = votingResult.context.dayOfWeek;

        // Validar índices
        ses = MathMax(0, MathMin(2, ses));
        vol = MathMax(0, MathMin(1, vol));
        dir = MathMax(0, MathMin(1, dir));

        Print("📚 Aprendiendo trade #", m_totalSystemTrades,
              " | ", won ? "✓ WIN" : "✗ LOSS",
              " | Profit: $", DoubleToString(profit, 2),
              " | Context: ", votingResult.context.contextID);

        // Actualizar cada indicador que participó
        for(int i = 0; i < 5; i++) {
            if(!votingResult.weights[i].isActive) continue;

            // Actualizar celda contextual específica
            m_performanceMatrix[i][ses][vol][dir].UpdateResult(won, profit, hour, day, barsToClose);

            // Actualizar métricas globales del indicador
            m_specializations[i].globalMetrics.Update(won, profit, barsToClose);

            // Log
            ContextualPerformanceCell cell = m_performanceMatrix[i][ses][vol][dir];
            Print("  └─ ", m_specializations[i].indicatorName,
                  " | WR: ", DoubleToString(cell.metrics.winRate * 100, 1), "%",
                  " | Trades: ", cell.metrics.totalTrades,
                  " | Expertise: ", GetExpertiseName(cell.expertiseLevel),
                  " | Weight: ", DoubleToString(votingResult.weights[i].finalWeight, 3));
        }

        // Verificar si es momento de re-evaluar
        if(m_tradesSinceLastReeval >= m_tradesUntilReeval) {
            Print("🔄 Iniciando re-evaluación periódica...");
            ReevaluateSpecializations();
            m_tradesSinceLastReeval = 0;
        }

        // Verificar si es momento de guardar
        if(m_tradesSinceLastSave >= m_tradesUntilSave) {
            SavePerformanceData();
            m_tradesSinceLastSave = 0;
        }
    }

    //+------------------------------------------------------------------+
    //| Re-evaluar especializaciones (cada N trades)                    |
    //+------------------------------------------------------------------+
    void ReevaluateSpecializations() {
        Print("═══════════════════════════════════════════════════════════════");
        Print("  🔄 RE-EVALUANDO ESPECIALIZACIONES");
        Print("═══════════════════════════════════════════════════════════════");

        // Limpiar especializaciones actuales
        for(int i = 0; i < 5; i++) {
            m_specializations[i].expertContextCount = 0;
            m_specializations[i].competentContextCount = 0;
            m_specializations[i].bestContextScore = 0.0;
            m_specializations[i].bestContextID = "";
        }

        // Analizar cada contexto y asignar especializaciones
        for(int ses = 0; ses < 3; ses++) {
            for(int vol = 0; vol < 2; vol++) {
                for(int dir = 0; dir < 2; dir++) {
                    // Encontrar mejor indicador en este contexto
                    int bestInd = -1;
                    double bestScore = 0.0;

                    for(int ind = 0; ind < 5; ind++) {
                        ContextualPerformanceCell cell = m_performanceMatrix[ind][ses][vol][dir];

                        if(!cell.hasEnoughSamples) continue;

                        double score = cell.GetPerformanceScore();

                        // Actualizar mejor contexto del indicador
                        if(score > m_specializations[ind].bestContextScore) {
                            m_specializations[ind].bestContextScore = score;
                            m_specializations[ind].bestContextID = cell.context.GenerateID();
                            m_specializations[ind].bestContextExpertise = cell.expertiseLevel;
                        }

                        // Agregar a listas de especialización
                        if(cell.expertiseLevel >= EXPERTISE_EXPERT) {
                            m_specializations[ind].AddExpertContext(cell.context.GenerateID());
                        }

                        // Tracking mejor en contexto
                        if(score > bestScore) {
                            bestScore = score;
                            bestInd = ind;
                        }
                    }

                    if(bestInd >= 0) {
                        string contextName = GetContextName(ses, vol, dir);
                        Print("  📍 ", contextName, " → ",
                              m_specializations[bestInd].indicatorName,
                              " (Score: ", DoubleToString(bestScore, 3), ")");
                    }
                }
            }
        }

        // Calcular ranking global
        CalculateGlobalRankings();

        // Mostrar resumen
        Print("\n┌─ ESPECIALIZACIONES ACTUALIZADAS ─────────────────────────────┐");
        for(int i = 0; i < 5; i++) {
            Print("│ ", m_specializations[i].GetSpecializationSummary());
        }
        Print("└───────────────────────────────────────────────────────────────┘");

        m_lastReevalTime = TimeCurrent();

        Print("═══════════════════════════════════════════════════════════════\n");
    }

    //+------------------------------------------------------------------+
    //| Generar reporte de performance completo                         |
    //+------------------------------------------------------------------+
    void PrintPerformanceReport() {
        Print("\n╔═══════════════════════════════════════════════════════════════╗");
        Print("║         📊 REPORTE DE PERFORMANCE - VOTING SYSTEM v4.0      ║");
        Print("╚═══════════════════════════════════════════════════════════════╝");

        Print("\n┌─ ESTADÍSTICAS GLOBALES ──────────────────────────────────────┐");
        Print("│ Total de Trades del Sistema: ", m_totalSystemTrades);
        Print("│ Tiempo Activo: ", (TimeCurrent() - m_systemStartTime) / 3600, " horas");
        Print("│ Última Re-evaluación: ", TimeToString(m_lastReevalTime));
        Print("│ Próxima Re-evaluación: ", m_tradesUntilReeval - m_tradesSinceLastReeval, " trades");
        Print("└───────────────────────────────────────────────────────────────┘");

        Print("\n┌─ PERFORMANCE POR INDICADOR (GLOBAL) ─────────────────────────┐");
        for(int i = 0; i < 5; i++) {
            PerformanceMetrics m = m_specializations[i].globalMetrics;
            Print(StringFormat("│ #%d %s",
                m_specializations[i].globalRank,
                m_specializations[i].indicatorName));
            Print(StringFormat("│    Trades: %d | WR: %.1f%% | Profit: $%.2f | Sharpe: %.2f",
                m.totalTrades, m.winRate * 100, m.totalProfit, m.sharpeRatio));
            Print(StringFormat("│    Streak: %d | MaxDD: $%.2f | Expertise Zones: %d",
                m.currentStreak, m.maxDrawdown, m_specializations[i].expertContextCount));
        }
        Print("└───────────────────────────────────────────────────────────────┘");

        Print("\n┌─ TOP CONTEXTOS POR INDICADOR ────────────────────────────────┐");
        for(int i = 0; i < 5; i++) {
            Print("│ ", m_specializations[i].indicatorName, ":");
            Print("│    Best Context: ", m_specializations[i].bestContextID,
                  " (Score: ", DoubleToString(m_specializations[i].bestContextScore, 3), ")");
            Print("│    Expertise: ", GetExpertiseName(m_specializations[i].bestContextExpertise));
        }
        Print("└───────────────────────────────────────────────────────────────┘");

        Print("\n┌─ MATRIZ DE CONTEXTOS (Top Performers) ───────────────────────┐");
        string sessions[] = {"ASIA", "LONDON", "NY"};
        string vols[] = {"LOW_VOL", "HIGH_VOL"};
        string dirs[] = {"BEARISH", "BULLISH"};

        for(int ses = 0; ses < 3; ses++) {
            for(int vol = 0; vol < 2; vol++) {
                for(int dir = 0; dir < 2; dir++) {
                    // Encontrar top 2 indicadores en este contexto
                    int topInds[2] = {-1, -1};
                    double topScores[2] = {0.0, 0.0};

                    for(int ind = 0; ind < 5; ind++) {
                        ContextualPerformanceCell cell = m_performanceMatrix[ind][ses][vol][dir];
                        if(!cell.hasEnoughSamples) continue;

                        double score = cell.GetPerformanceScore();

                        if(score > topScores[0]) {
                            topScores[1] = topScores[0];
                            topInds[1] = topInds[0];
                            topScores[0] = score;
                            topInds[0] = ind;
                        } else if(score > topScores[1]) {
                            topScores[1] = score;
                            topInds[1] = ind;
                        }
                    }

                    if(topInds[0] >= 0) {
                        string contextName = sessions[ses] + "_" + vols[vol] + "_" + dirs[dir];
                        Print(StringFormat("│ %s: #1 %s (%.3f) | #2 %s (%.3f)",
                            contextName,
                            m_specializations[topInds[0]].indicatorName, topScores[0],
                            topInds[1] >= 0 ? m_specializations[topInds[1]].indicatorName : "N/A",
                            topInds[1] >= 0 ? topScores[1] : 0.0));
                    }
                }
            }
        }
        Print("└───────────────────────────────────────────────────────────────┘");

        Print("╚═══════════════════════════════════════════════════════════════╝\n");
    }

    //+------------------------------------------------------------------+
    //| Exportar a CSV                                                   |
    //+------------------------------------------------------------------+
    bool ExportToCSV(string filename = "") {
        if(filename == "") {
            filename = "AdaptiveVoting_" + _Symbol + "_" + IntegerToString(TimeCurrent()) + ".csv";
        }

        int handle = FileOpen(filename, FILE_WRITE|FILE_CSV|FILE_ANSI, ",");
        if(handle == INVALID_HANDLE) {
            Print("❌ ERROR: No se pudo crear archivo CSV: ", filename);
            return false;
        }

        // Header
        FileWrite(handle, "Indicator", "Session", "Volatility", "Direction",
                  "Trades", "WinRate", "Profit", "Sharpe", "MaxDD",
                  "Expertise", "PerformanceScore");

        // Datos
        string sessions[] = {"ASIA", "LONDON", "NY"};
        string vols[] = {"LOW", "HIGH"};
        string dirs[] = {"BEARISH", "BULLISH"};

        for(int ind = 0; ind < 5; ind++) {
            for(int ses = 0; ses < 3; ses++) {
                for(int vol = 0; vol < 2; vol++) {
                    for(int dir = 0; dir < 2; dir++) {
                        ContextualPerformanceCell cell = m_performanceMatrix[ind][ses][vol][dir];

                        FileWrite(handle,
                            m_specializations[ind].indicatorName,
                            sessions[ses],
                            vols[vol],
                            dirs[dir],
                            cell.metrics.totalTrades,
                            DoubleToString(cell.metrics.winRate, 4),
                            DoubleToString(cell.metrics.totalProfit, 2),
                            DoubleToString(cell.metrics.sharpeRatio, 3),
                            DoubleToString(cell.metrics.maxDrawdown, 2),
                            GetExpertiseName(cell.expertiseLevel),
                            DoubleToString(cell.GetPerformanceScore(), 4));
                    }
                }
            }
        }

        FileClose(handle);
        Print("✅ Performance exportado a: ", filename);
        return true;
    }

    //+------------------------------------------------------------------+
    //| Guardar datos de performance                                     |
    //+------------------------------------------------------------------+
    void SavePerformanceData() {
        string filename = "AdaptiveVoting_" + _Symbol + ".bin";
        int handle = FileOpen(filename, FILE_WRITE|FILE_BIN);

        if(handle == INVALID_HANDLE) {
            Print("⚠ WARNING: No se pudo guardar performance data");
            return;
        }

        // Guardar metadata
        FileWriteInteger(handle, m_totalSystemTrades);
        FileWriteLong(handle, m_systemStartTime);
        FileWriteLong(handle, m_lastReevalTime);

        // Guardar matriz de performance
        for(int ind = 0; ind < 5; ind++) {
            for(int ses = 0; ses < 3; ses++) {
                for(int vol = 0; vol < 2; vol++) {
                    for(int dir = 0; dir < 2; dir++) {
                        ContextualPerformanceCell cell = m_performanceMatrix[ind][ses][vol][dir];

                        // Guardar métricas clave
                        FileWriteInteger(handle, cell.metrics.totalTrades);
                        FileWriteInteger(handle, cell.metrics.wins);
                        FileWriteDouble(handle, cell.metrics.totalProfit);
                        FileWriteDouble(handle, cell.metrics.emaWinRate);
                        FileWriteDouble(handle, cell.metrics.sharpeRatio);
                        FileWriteDouble(handle, cell.metrics.maxDrawdown);
                        FileWriteInteger(handle, cell.metrics.currentStreak);
                        FileWriteLong(handle, cell.lastUpdate);
                    }
                }
            }
        }

        FileClose(handle);
        Print("💾 Performance data guardado: ", filename);
    }

    //+------------------------------------------------------------------+
    //| Cargar datos de performance                                      |
    //+------------------------------------------------------------------+
    void LoadPerformanceData() {
        string filename = "AdaptiveVoting_" + _Symbol + ".bin";

        if(!FileIsExist(filename)) {
            Print("ℹ No hay datos previos para cargar");
            return;
        }

        int handle = FileOpen(filename, FILE_READ|FILE_BIN);
        if(handle == INVALID_HANDLE) return;

        // Cargar metadata
        m_totalSystemTrades = FileReadInteger(handle);
        m_systemStartTime = (datetime)FileReadLong(handle);
        m_lastReevalTime = (datetime)FileReadLong(handle);

        // Cargar matriz
        for(int ind = 0; ind < 5; ind++) {
            for(int ses = 0; ses < 3; ses++) {
                for(int vol = 0; vol < 2; vol++) {
                    for(int dir = 0; dir < 2; dir++) {
                        m_performanceMatrix[ind][ses][vol][dir].metrics.totalTrades = FileReadInteger(handle);
                        m_performanceMatrix[ind][ses][vol][dir].metrics.wins = FileReadInteger(handle);
                        m_performanceMatrix[ind][ses][vol][dir].metrics.totalProfit = FileReadDouble(handle);
                        m_performanceMatrix[ind][ses][vol][dir].metrics.emaWinRate = FileReadDouble(handle);
                        m_performanceMatrix[ind][ses][vol][dir].metrics.sharpeRatio = FileReadDouble(handle);
                        m_performanceMatrix[ind][ses][vol][dir].metrics.maxDrawdown = FileReadDouble(handle);
                        m_performanceMatrix[ind][ses][vol][dir].metrics.currentStreak = FileReadInteger(handle);
                        m_performanceMatrix[ind][ses][vol][dir].lastUpdate = (datetime)FileReadLong(handle);

                        // Recalcular métricas derivadas
                        m_performanceMatrix[ind][ses][vol][dir].metrics.RecalculateMetrics();
                        m_performanceMatrix[ind][ses][vol][dir].UpdateExpertiseLevel();
                    }
                }
            }
        }

        FileClose(handle);
        Print("✅ Performance data cargado: ", m_totalSystemTrades, " trades históricos");
    }

private:
    //+------------------------------------------------------------------+
    //| Calcular qué tan bien match el indicador con el contexto        |
    //+------------------------------------------------------------------+
    double CalculateContextMatch(int indicatorId, MarketContextSnapshot &context) {
        // Verificar si el indicador es experto en este contexto exacto
        if(m_specializations[indicatorId].IsExpertIn(context.contextID)) {
            return 1.0;  // Match perfecto
        }

        // Si no es experto exacto, buscar contextos similares
        int ses = (int)context.session;
        int vol = (int)context.volatility;
        int dir = (int)context.direction;

        // Validar
        ses = MathMax(0, MathMin(2, ses));
        vol = MathMax(0, MathMin(1, vol));
        dir = MathMax(0, MathMin(1, dir));

        ContextualPerformanceCell cell = m_performanceMatrix[indicatorId][ses][vol][dir];

        // Match basado en expertise level
        if(cell.expertiseLevel == EXPERTISE_MASTER) return 0.95;
        if(cell.expertiseLevel == EXPERTISE_EXPERT) return 0.85;
        if(cell.expertiseLevel == EXPERTISE_COMPETENT) return 0.70;
        if(cell.expertiseLevel == EXPERTISE_NOVICE) return 0.50;

        return 0.30;  // Sin datos suficientes
    }

    //+------------------------------------------------------------------+
    //| Normalizar pesos para que sumen 1.0                             |
    //+------------------------------------------------------------------+
    void NormalizeWeights(DynamicWeight &weights[]) {
        double sum = 0.0;
        int activeCount = 0;

        for(int i = 0; i < 5; i++) {
            if(weights[i].isActive) {
                sum += weights[i].finalWeight;
                activeCount++;
            }
        }

        if(sum < 0.001 || activeCount == 0) {
            // Fallback: distribuir uniformemente
            for(int i = 0; i < 5; i++) {
                weights[i].finalWeight = 0.20;
                weights[i].isActive = true;
            }
            return;
        }

        // Normalizar
        for(int i = 0; i < 5; i++) {
            if(weights[i].isActive) {
                weights[i].finalWeight = weights[i].finalWeight / sum;
            }
        }
    }

    //+------------------------------------------------------------------+
    //| Calcular rankings globales                                       |
    //+------------------------------------------------------------------+
    void CalculateGlobalRankings() {
        // Crear array de scores
        double scores[5];
        int indices[5];

        for(int i = 0; i < 5; i++) {
            indices[i] = i;
            PerformanceMetrics m = m_specializations[i].globalMetrics;

            // Score combinado
            double wrScore = m.winRate;
            double sharpeScore = MathMin(1.0, (m.sharpeRatio + 1.0) / 3.0);
            double pfScore = MathMin(1.0, m.profitFactor / 3.0);

            scores[i] = wrScore * 0.4 + sharpeScore * 0.3 + pfScore * 0.3;
        }

        // Bubble sort (simple para 5 elementos)
        for(int i = 0; i < 4; i++) {
            for(int j = 0; j < 4 - i; j++) {
                if(scores[j] < scores[j + 1]) {
                    // Swap scores
                    double tempScore = scores[j];
                    scores[j] = scores[j + 1];
                    scores[j + 1] = tempScore;

                    // Swap indices
                    int tempIdx = indices[j];
                    indices[j] = indices[j + 1];
                    indices[j + 1] = tempIdx;
                }
            }
        }

        // Asignar ranks
        for(int i = 0; i < 5; i++) {
            m_specializations[indices[i]].globalRank = i + 1;
        }
    }

    //+------------------------------------------------------------------+
    //| Helpers                                                          |
    //+------------------------------------------------------------------+
    string GetExpertiseName(ENUM_EXPERTISE_LEVEL level) {
        switch(level) {
            case EXPERTISE_MASTER: return "MASTER";
            case EXPERTISE_EXPERT: return "EXPERT";
            case EXPERTISE_COMPETENT: return "COMPETENT";
            case EXPERTISE_NOVICE: return "NOVICE";
            default: return "NONE";
        }
    }

    string GetContextName(int ses, int vol, int dir) {
        string sessions[] = {"ASIA", "LONDON", "NY"};
        string vols[] = {"LOW", "HIGH"};
        string dirs[] = {"BEAR", "BULL"};

        return sessions[ses] + "_" + vols[vol] + "_" + dirs[dir];
    }
};

//+------------------------------------------------------------------+#endif // ADAPTIVE_VOTING_SYSTEM_MQH