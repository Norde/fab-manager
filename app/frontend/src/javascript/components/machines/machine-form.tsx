import React from 'react';
import { SubmitHandler, useForm, useWatch } from 'react-hook-form';
import { Machine } from '../../models/machine';
import MachineAPI from '../../api/machine';
import { useTranslation } from 'react-i18next';
import { FormInput } from '../form/form-input';
import { FormImageUpload } from '../form/form-image-upload';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { ErrorBoundary } from '../base/error-boundary';
import { FormRichText } from '../form/form-rich-text';
import { FormSwitch } from '../form/form-switch';

declare const Application: IApplication;

interface MachineFormProps {
  action: 'create' | 'update',
  machine?: Machine,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

/**
 * Form to edit or create machines
 */
export const MachineForm: React.FC<MachineFormProps> = ({ action, machine, onError, onSuccess }) => {
  const { handleSubmit, register, control, setValue, formState } = useForm<Machine>({ defaultValues: { ...machine } });
  const output = useWatch<Machine>({ control });
  const { t } = useTranslation('admin');

  /**
   * Callback triggered when the user validates the machine form: handle create or update
   */
  const onSubmit: SubmitHandler<Machine> = (data: Machine) => {
    MachineAPI[action](data).then(() => {
      onSuccess(t(`app.admin.machine_form.${action}_success`));
    }).catch(error => {
      onError(error);
    });
  };

  return (
    <form className="machine-form" onSubmit={handleSubmit(onSubmit)}>
      <FormInput register={register} id="name"
                 formState={formState}
                 rules={{ required: true }}
                 label={t('app.admin.machine_form.name')} />
      <FormImageUpload setValue={setValue}
                       register={register}
                       control={control}
                       formState={formState}
                       rules={{ required: true }}
                       id="machine_image_attributes"
                       accept="image/*"
                       defaultImage={output.machine_image_attributes}
                       label={t('app.admin.machine_form.illustration')} />
      <FormRichText control={control}
                    id="description"
                    rules={{ required: true }}
                    label={t('app.admin.machine_form.description')}
                    limit={null}
                    heading bulletList blockquote link video image />
      <FormRichText control={control}
                    id="spec"
                    rules={{ required: true }}
                    label={t('app.admin.machine_form.technical_specifications')}
                    limit={null}
                    heading bulletList blockquote link video image />

      <FormSwitch control={control}
                  id="disabled"
                  label={t('app.admin.machine_form.disable_machine')}
                  tooltip={t('app.admin.machine_form.disabled_help')} />
    </form>
  );
};

const MachineFormWrapper: React.FC<MachineFormProps> = (props) => {
  return (
    <Loader>
      <ErrorBoundary>
        <MachineForm {...props} />
      </ErrorBoundary>
    </Loader>
  );
};

Application.Components.component('machineForm', react2angular(MachineFormWrapper, ['action', 'machine', 'onError', 'onSuccess']));
