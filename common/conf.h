#ifndef CONF_H
#define CONF_H

enum channel_ids {
    CPU1 = 0,
    TRIGGER1 = 1,
    CPU2 = 2,
    TRIGGER2 = 3,
    CHAN5 = 4,
    CHAN6 = 5,
    CHAN7 = 6,
    CHAN8 = 7
};

#define NI_CHANNELS "Dev1/ai0, Dev1/ai1, Dev1/ai2, Dev1/ai3," \
    "Dev1/ai4, Dev1/ai5, Dev1/ai6, Dev1/ai7"
#define U_MIN ((double)-0.2)
#define U_MAX ((double)0.2)
#define CLK_SRC "OnboardClock"
#define SAMPLING_RATE ((unsigned int)30000)
#define TIMEOUT ((unsigned int)10)

#endif
