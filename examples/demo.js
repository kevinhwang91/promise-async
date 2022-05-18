async function defuse(ms) {
    return new Promise((resolve, reject) => {
        setTimeout(() => {
            resolve(ms)
        }, ms)
    })
}

async function bomb(ms) {
    return new Promise((resolve, reject) => {
        setTimeout(() => {
            reject(ms)
        }, ms)
    })
}

async function race() {
    return Promise.race([
        defuse(500 + Math.ceil(Math.random() * 500)),
        bomb(800 + Math.ceil(Math.random() * 200)),
    ])
}

async function play() {
    console.info('Game start!')
    let cnt = 0
    try {
        while (true) {
            let ms = await race()
            cnt = cnt + ms
            console.info(`Defuse after ${ms}ms~`)
        }
    } catch (msErr) {
        cnt = cnt + msErr
        console.info(`Bomb after ${msErr}ms~`)
    }

    console.info(`Game end after ${cnt}ms!`)

    await {
        then: function(resolve, reject) {
            setTimeout(() => {
                reject(this.message)
            }, 1000)
        },
        message: 'try to throw an error :)'
    }
}

Promise.resolve().then((value) => {
    console.info('In next tick')
})

console.info('In main')

play().finally(() => {
    console.info('Before throwing UnhandledPromiseRejection on finally!')
})
