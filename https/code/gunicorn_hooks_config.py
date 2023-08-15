def ssl_context(conf, default_ssl_context_factory):
    import ssl, os
    context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH, cafile=conf.ca_certs)
    context.load_cert_chain(certfile=conf.certfile, keyfile=conf.keyfile, password=os.environ["AWS_ACM_CERT_PASS"])
    context.verify_mode = conf.cert_reqs
    if conf.ciphers:
        context.set_ciphers(conf.ciphers)
    return context
